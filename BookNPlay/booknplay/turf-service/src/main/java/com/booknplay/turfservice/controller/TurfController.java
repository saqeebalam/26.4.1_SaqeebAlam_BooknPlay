package com.booknplay.turfservice.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TurfController {

    @GetMapping("/turf/test")
    public String getUserServiceData() {
        return "fromTurfService";
    }
}