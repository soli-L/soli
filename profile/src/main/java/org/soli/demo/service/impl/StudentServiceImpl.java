package org.soli.demo.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.soli.demo.mapper.StudentMapper;
import org.soli.demo.pojo.Student;
import org.soli.demo.service.StudentService;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

@Service
public class StudentServiceImpl extends ServiceImpl<StudentMapper, Student> implements StudentService {

    @Resource
    StudentMapper studentMapper;
    @Override
    @Cacheable(value = "student" ,key = "#id")
    public List<Student> getStudentList(Integer id) {

        return studentMapper.getStudentList(id);
    }
}
