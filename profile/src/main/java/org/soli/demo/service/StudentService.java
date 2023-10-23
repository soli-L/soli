package org.soli.demo.service;

import com.baomidou.mybatisplus.extension.service.IService;
import org.soli.demo.pojo.Student;

import java.util.List;

public interface StudentService extends IService<Student> {

    List<Student> getStudentList(Integer id);
}
