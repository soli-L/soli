package org.soli.demo.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.soli.demo.pojo.User;
import org.soli.demo.service.UserService;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import java.util.List;

@RestController
@RequestMapping("/user")
public class UserController {

    @Resource
    UserService userService;

    @RequestMapping("/user")
    public List<User> getUserList() {
        return userService.list();
    }

    @RequestMapping("/login")
    public User login(@RequestParam String phone, @RequestParam String password) {
        QueryWrapper<User> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("phone", phone).eq("password", password).last("limit 1");
        return userService.getOne(queryWrapper);
    }

    @RequestMapping("/newUser")
    public boolean save(@RequestBody User user) {
        return userService.save(user);
    }

}
