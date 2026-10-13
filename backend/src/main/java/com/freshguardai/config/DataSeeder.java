package com.freshguardai.config;

import com.freshguardai.model.*;
import com.freshguardai.repository.*;
import com.freshguardai.service.ProductService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataSeeder implements CommandLineRunner {
    private static final String DEMO_STORE = "FreshGuard Supermarket #101";
    private final UserRepository userRepository;
    private final ProductRepository productRepository;
    private final NotificationRepository notificationRepository;
    private final TaskRepository taskRepository;
    private final InventoryLogRepository inventoryLogRepository;
    private final DiscountRepository discountRepository;
    private final PasswordEncoder passwordEncoder;
    private final ProductService productService;

    public DataSeeder(UserRepository userRepository, ProductRepository productRepository,
                      NotificationRepository notificationRepository, TaskRepository taskRepository,
                      InventoryLogRepository inventoryLogRepository, DiscountRepository discountRepository,
                      PasswordEncoder passwordEncoder, ProductService productService) {
        this.userRepository=userRepository; this.productRepository=productRepository;
        this.notificationRepository=notificationRepository; this.taskRepository=taskRepository; this.inventoryLogRepository=inventoryLogRepository; this.discountRepository=discountRepository;
        this.passwordEncoder=passwordEncoder; this.productService=productService;
    }

    @Override public void run(String... args) {
        seedUsers();
        migrateLegacyProducts();
    }

    private void seedUsers() {
        saveUser("admin@freshguard.local","Administrator","9876543210","Admin@123",Role.ADMIN,"FreshGuard Central");
        saveUser("manager@freshguard.local","Store Manager","9876543211","Manager@123",Role.STORE_MANAGER,DEMO_STORE);
        saveUser("employee@freshguard.local","Store Staff","9876543212","Employee@123",Role.EMPLOYEE,DEMO_STORE);
    }

    private void saveUser(String email,String name,String phone,String password,Role role,String store) {
        User u=userRepository.findByEmail(email).orElseGet(User::new);
        u.setName(name);u.setEmail(email);u.setPhone(phone);u.setRole(role);u.setStoreName(store);u.setActive(true);
        if(u.getPassword()==null||u.getPassword().isBlank())u.setPassword(passwordEncoder.encode(password));
        u.setCreatedAt(u.getCreatedAt()==null?java.time.LocalDateTime.now():u.getCreatedAt());u.setUpdatedAt(java.time.LocalDateTime.now());userRepository.save(u);
    }

    private void migrateLegacyProducts() {
        // Products from older versions did not have store ownership. Keep them with the demo store
        // instead of leaking them into every newly registered account.
        productRepository.findAll().forEach(p -> {
            if(p.getStoreName()==null||p.getStoreName().isBlank()||"Metro Supermarket Central".equals(p.getStoreName())) {
                p.setStoreName(DEMO_STORE);
                if(p.getUnit()==null||p.getUnit().isBlank())p.setUnit("units");
                productService.saveOrRefreshProduct(p); productRepository.save(p);
            }
        });
        notificationRepository.findAll().forEach(n -> { if(n.getStoreName()==null||n.getStoreName().isBlank()){ n.setStoreName(DEMO_STORE); notificationRepository.save(n); } });
        taskRepository.findAll().forEach(t -> { if(t.getStoreName()==null||t.getStoreName().isBlank()){ t.setStoreName(DEMO_STORE); taskRepository.save(t); } });
        inventoryLogRepository.findAll().forEach(l -> { if(l.getStoreName()==null||l.getStoreName().isBlank()){ l.setStoreName(DEMO_STORE); inventoryLogRepository.save(l); } });
        discountRepository.findAll().forEach(d -> { if(d.getStoreName()==null||d.getStoreName().isBlank()){ d.setStoreName(DEMO_STORE); discountRepository.save(d); } });
    }

}
