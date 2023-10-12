package org.soli.demo.controller;

import org.soli.demo.pojo.Student;
import org.soli.demo.service.StudentService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import java.util.List;

@RestController
public class DemoController {

    @Resource
    private StudentService studentService;

    @RequestMapping("/student")
    public List<Student> getStudentList(){
        return studentService.list();
    }

    @RequestMapping("/hello")
    public String Hello() {
        return "Hello World!";
    }
}
