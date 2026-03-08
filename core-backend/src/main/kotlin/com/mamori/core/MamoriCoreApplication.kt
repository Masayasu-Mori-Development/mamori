package com.mamori.core

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class MamoriCoreApplication

fun main(args: Array<String>) {
    runApplication<MamoriCoreApplication>(*args)
}
