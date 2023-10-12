package org.soli.demo.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.soli.demo.pojo.Student;

import java.util.List;

@Mapper
public interface StudentMapper extends BaseMapper<Student> {
    public List<Student> getStudentList();
}
