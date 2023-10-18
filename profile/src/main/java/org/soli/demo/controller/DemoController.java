package org.soli.demo.controller;

import org.soli.demo.pojo.Student;
import org.soli.demo.service.StudentService;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;

@RestController
public class DemoController {

    @Resource
    private StudentService studentService;

    @RequestMapping("/student")
    public List<Student> getStudentList() {
        return studentService.list();
    }

    @RequestMapping("/addStudent")
    public boolean addStudentList(@RequestParam String name, @RequestParam int age) {
        Student student = new Student();
        student.setName(name);
        student.setAge(age);
        boolean save = studentService.save(student);
        return save;

    }



    @RequestMapping("/hello")
    public String Hello() {
        return "Hello World!";
    }
}
