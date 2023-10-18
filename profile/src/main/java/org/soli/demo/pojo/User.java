package org.soli.demo.pojo;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

@TableName("users")
@Getter
@Setter
public class User {
   @TableId("user_id")
    private Integer userId;

    @TableField("user_name")
    private String userName;

    private String phone;

    private String email;

    private String password;

    private Date birth;
}
