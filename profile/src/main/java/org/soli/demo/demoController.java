package org.soli.demo;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class demoController {
    @RequestMapping("/hello")
    public String Hello(){
        return "Hello World!";
    }
}
