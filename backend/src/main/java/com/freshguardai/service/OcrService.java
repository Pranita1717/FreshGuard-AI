package com.freshguardai.service;

import com.freshguardai.dto.OcrResponse;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class OcrService {
    private static final Pattern PREFIX_DMY = Pattern.compile("(?i)(?:EXP(?:IRY)?(?:\\s*DATE)?|BEST\\s*BEFORE|USE\\s*BY|BB|BBD|EXP\\.?\\s*DATE)[:\\s\\-.]*([0-3]?\\d)[/\\-.]([0-1]?\\d)[/\\-.](\\d{4}|\\d{2})");
    private static final Pattern ISO = Pattern.compile("(?i)(?:EXP(?:IRY)?(?:\\s*DATE)?|BEST\\s*BEFORE|USE\\s*BY|BB|BBD)?[:\\s\\-.]*(\\d{4})[/\\-.]([0-1]?\\d)[/\\-.]([0-3]?\\d)");
    private static final Pattern MONTH_YEAR = Pattern.compile("(?i)(?:EXP(?:IRY)?(?:\\s*DATE)?|BEST\\s*BEFORE|USE\\s*BY|BB|BBD)[:\\s\\-.]*([0-1]?\\d)[/\\-](\\d{4})");
    private static final Pattern GENERAL = Pattern.compile("\\b([0-3]?\\d)[/\\-.]([0-1]?\\d)[/\\-.](\\d{4})\\b");

    public OcrResponse processImage(MultipartFile file,String text) {
        if(text!=null&&!text.isBlank()) return extractDateFromText(text);
        if(file!=null&&!file.isEmpty()) return new OcrResponse(null,"",0.0,null,null,"CLIENT_OCR_REQUIRED","Image received. Run the device/browser OCR engine and send the extracted text for date detection.");
        return new OcrResponse(null,"",0.0,null,null,"NO_DATE_FOUND","No image or text was provided. Please enter the expiry date manually.");
    }

    public OcrResponse extractDateFromText(String text) {
        if(text==null||text.isBlank()) return new OcrResponse(null,"",0.0,null,null,"NO_DATE_FOUND","No readable text found. Please verify the date manually.");
        Matcher m=PREFIX_DMY.matcher(text); if(m.find()){LocalDate d=parseDate(normalizeYear(m.group(3)),m.group(2),m.group(1));if(d!=null)return success(format(d),m.group(0),0.95,d);}
        m=ISO.matcher(text); if(m.find()){LocalDate d=parseDate(m.group(1),m.group(2),m.group(3));if(d!=null)return success(format(d),m.group(0),0.92,d);}
        m=MONTH_YEAR.matcher(text); if(m.find()){try{int month=Integer.parseInt(m.group(1));int year=Integer.parseInt(m.group(2));LocalDate d=YearMonth.of(year,month).atEndOfMonth();return success(month+"/"+year,m.group(0),0.88,d);}catch(Exception ignored){}}
        m=GENERAL.matcher(text); if(m.find()){LocalDate d=parseDate(m.group(3),m.group(2),m.group(1));if(d!=null)return new OcrResponse(format(d),m.group(0),0.80,"EXPIRY",d,"MANUAL_VERIFICATION_REQUIRED","Date detected from OCR text. Please verify before saving.");}
        return new OcrResponse(null,text,0.0,null,null,"NO_DATE_FOUND","Could not reliably detect an expiry date. Please verify the date manually.");
    }
    private OcrResponse success(String date,String raw,double confidence,LocalDate d){return new OcrResponse(date,raw,confidence,"EXPIRY",d,"SUCCESS","Please verify the extracted date before saving.");}
    private LocalDate parseDate(String year,String month,String day){try{return LocalDate.of(Integer.parseInt(year),Integer.parseInt(month),Integer.parseInt(day));}catch(Exception e){return null;}}
    private String normalizeYear(String y){if(y==null)return "";if(y.length()==2){int n=Integer.parseInt(y);return (n>=70?"19":"20")+y;}return y;}
    private String format(LocalDate d){return String.format("%02d/%02d/%04d",d.getDayOfMonth(),d.getMonthValue(),d.getYear());}
}
