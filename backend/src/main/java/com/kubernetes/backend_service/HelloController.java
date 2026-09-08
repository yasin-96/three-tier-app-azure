package com.kubernetes.backend_service;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin
@RequestMapping("/api")
public class HelloController {
    @PostMapping("/hello")
    public void hello(@RequestBody HelloModel helloModel ) {
        System.out.println(helloModel.getMessage());
    }

    @GetMapping
    public ResponseEntity<String> helloworld() {
       return ResponseEntity.ok("hello world");
    }
}
