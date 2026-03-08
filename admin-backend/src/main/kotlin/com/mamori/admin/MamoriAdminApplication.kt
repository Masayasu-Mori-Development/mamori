package com.mamori.admin

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class MamoriAdminApplication

fun main(args: Array<String>) {
    runApplication<MamoriAdminApplication>(*args)
}
