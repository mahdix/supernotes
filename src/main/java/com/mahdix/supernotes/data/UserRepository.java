package com.mahdix.supernotes.data;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findAllByUsernameAndPassword(String userName, String password);
    User findFirstByUsername(String userName);
    List<User> findAllByIdIn(List<Long> userIds);

}
