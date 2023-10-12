package org.soli.demo.pojo;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
@TableName("student")
public class Student {
    private String name;

    private Integer age;

    private Integer id;
}

