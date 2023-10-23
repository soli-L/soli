package org.soli.demo.pojo;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;

import java.io.Serializable;

@Setter
@Getter
@TableName("student")
public class Student implements Serializable {
    private String name;

    private Integer age;

    private Integer id;
}

