package ch.qos.logback.core.dsl

import ch.qos.logback.classic.encoder.PatternLayoutEncoder
import ch.qos.logback.classic.spi.ILoggingEvent
import ch.qos.logback.core.encoder.Encoder
import ch.qos.logback.core.rolling.*
import ch.qos.logback.core.util.FileSize
import ch.qos.logback.core.util.OptionHelper

typealias MyRollingFileAppender = RollingFileAppender<ILoggingEvent>
fun Configuration.rollingFileAppender(name: String = "rollingFile", block: () -> Unit = {}) {
    val loggerContext = context
    appender(::MyRollingFileAppender) {
        this.name = name
        this.context = loggerContext
        encoder("%d - %msg%n")

        val parent = this
        rollingPolicy(::FixedWindowRollingPolicy) {
            setParent(parent)

            // TODO: Make this an absolute path to the app's data dir
            fileNamePattern = "/tmp/logback%d-%i.log.gz"
            file("/tmp/logback/%d.log")

            context = loggerContext
            start()
        }
        triggeringPolicy(::SizeBasedTriggeringPolicy) {
            val policy = this as SizeBasedTriggeringPolicy
            policy.maxFileSize = FileSize.valueOf("1MB")
            context = loggerContext
            start()
        }
        start()

        block()
    }
}

fun <E: ILoggingEvent> RollingFileAppender<E>.encoder(pattern: String) {
    val context = this.context
    @Suppress("UNCHECKED_CAST")
    encoder = PatternLayoutEncoder().apply {
        this.pattern = pattern
        this.context = context
        start()
    } as Encoder<E>
}

fun <E: ILoggingEvent> RollingFileAppender<E>.file(name: String) {
    // TODO: Automatically convert relative path to absolute local-file path
    // Android requires absolute path
    file = OptionHelper.substVars(name, context)
}

fun <E: ILoggingEvent, R: RollingPolicy> RollingFileAppender<E>.rollingPolicy(policy: () -> R, block: R.() -> Unit = {}) {
    rollingPolicy = policy().apply(block)
}

typealias MySizeBasedTriggeringPolicy = SizeBasedTriggeringPolicy<ILoggingEvent>
fun <E: ILoggingEvent, R: TriggeringPolicy<E>> RollingFileAppender<E>.triggeringPolicy(policy: () -> R, block: R.() -> Unit = {}) {
    triggeringPolicy = policy().apply(block)
}

