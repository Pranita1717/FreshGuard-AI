package com.freshguardai.service;

import com.freshguardai.dto.LoginRequest;
import com.freshguardai.dto.LoginResponse;
import com.freshguardai.dto.RegisterRequest;
import com.freshguardai.exception.BadRequestException;
import com.freshguardai.exception.ResourceNotFoundException;
import com.freshguardai.model.LoginLog;
import com.freshguardai.model.Role;
import com.freshguardai.model.SystemLog;
import com.freshguardai.model.User;
import com.freshguardai.repository.LoginLogRepository;
import com.freshguardai.repository.SystemLogRepository;
import com.freshguardai.repository.UserRepository;
import com.freshguardai.security.JwtService;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final LoginLogRepository loginLogRepository;
    private final SystemLogRepository systemLogRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public UserService(UserRepository userRepository,
                       LoginLogRepository loginLogRepository,
                       SystemLogRepository systemLogRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.loginLogRepository = loginLogRepository;
        this.systemLogRepository = systemLogRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public LoginResponse login(LoginRequest request, String ipAddress) {
        User user = userRepository.findByEmail(request.getEmail().trim().toLowerCase())
                .orElse(null);

        if (user == null || !passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            loginLogRepository.save(new LoginLog(
                    user != null ? user.getId() : "UNKNOWN",
                    request.getEmail(),
                    user != null ? user.getRole() : null,
                    false,
                    ipAddress
            ));
            throw new BadCredentialsException("Invalid email or password");
        }

        if (!user.isActive()) {
            throw new BadRequestException("User account is deactivated");
        }

        loginLogRepository.save(new LoginLog(
                user.getId(),
                user.getEmail(),
                user.getRole(),
                true,
                ipAddress
        ));

        String token = jwtService.generateToken(user);

        return new LoginResponse(
                token,
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole().name(),
                user.getStoreName()
        );
    }

    public LoginResponse register(RegisterRequest request) {
        if (request.getRole() == Role.ADMIN) {
            throw new BadRequestException("ADMIN role cannot be registered publicly");
        }

        if (userRepository.existsByEmail(request.getEmail().trim().toLowerCase())) {
            throw new BadRequestException("Email is already registered: " + request.getEmail());
        }

        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Password and confirm password do not match");
        }

        User user = new User();
        user.setName(request.getName().trim());
        user.setEmail(request.getEmail().trim().toLowerCase());
        user.setPhone(request.getPhone().trim());
        user.setRole(request.getRole());
        user.setStoreName(request.getStoreName().trim());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setActive(true);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());

        User savedUser = userRepository.save(user);

        systemLogRepository.save(new SystemLog(
                "USER_REGISTERED",
                "New user registered: " + savedUser.getEmail() + " with role " + savedUser.getRole(),
                "INFO"
        ));

        String token = jwtService.generateToken(savedUser);

        return new LoginResponse(
                token,
                savedUser.getId(),
                savedUser.getName(),
                savedUser.getEmail(),
                savedUser.getRole().name(),
                savedUser.getStoreName()
        );
    }

    public User findById(String id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
    }

    public User findByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with email: " + email));
    }

    public List<User> findAll() {
        return userRepository.findAll();
    }

    public User updateProfile(String email, String name, String phone, String storeName) {
        User user = findByEmail(email);
        if (name != null && name.trim().length() >= 2) {
            user.setName(name.trim());
        }
        if (phone != null && phone.trim().matches("^[0-9]{10}$")) {
            user.setPhone(phone.trim());
        }
        // Store assignment is controlled by registration/admin policy and cannot be changed from the profile screen.
        user.setUpdatedAt(LocalDateTime.now());
        return userRepository.save(user);
    }
}
