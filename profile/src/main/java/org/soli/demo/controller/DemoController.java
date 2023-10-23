package org.soli.demo.controller;

import org.soli.demo.pojo.Student;
import org.soli.demo.service.StudentService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import java.util.List;

@RestController
@RequestMapping("/student")
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
        return studentService.save(student);
        
    }

    @RequestMapping("/getStudentById")
    public List<Student> getStudent(@RequestParam int id) {
        return studentService.getStudentList(id);
    }

    @RequestMapping("/hello")
    public String Hello() {
        return "Hello World!";
    }
}
