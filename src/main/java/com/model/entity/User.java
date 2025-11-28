package com.model.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import java.io.Serializable;
import java.time.LocalDateTime;

import java.io.Serial;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 用户 实体类。
 *
 * @author <a href="https://github.com/liyupi">程序员鱼皮</a>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@TableName("user")
public class User implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * id
     */
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /**
     * 账号
     */
    @TableField("userAccount")
    private String userAccount;

    /**
     * 密码
     */
    @TableField("userPassword")
    private String userPassword;

    /**
     * 用户昵称
     */
    @TableField("userName")
    private String userName;

    /**
     * 用户头像
     */
    @TableField("userAvatar")
    private String userAvatar;

    /**
     * 用户简介
     */
    @TableField("userProfile")
    private String userProfile;

    /**
     * 用户角色：user/admin
     */
    @TableField("userRole")
    private String userRole;

    /**
     * 编辑时间
     */
    @TableField("editTime")
    private LocalDateTime editTime;

    /**
     * 创建时间
     */
    @TableField("createTime")
    private LocalDateTime createTime;

    /**
     * 更新时间
     */
    @TableField("updateTime")
    private LocalDateTime updateTime;

    /**
     * 是否删除
     */
    @TableLogic
    @TableField("isDelete")
    private Integer isDelete;

}
