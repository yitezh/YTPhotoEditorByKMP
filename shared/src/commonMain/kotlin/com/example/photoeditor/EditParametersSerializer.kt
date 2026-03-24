package com.example.photoeditor

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

object EditParametersSerializer {

    private val json = Json { prettyPrint = false; ignoreUnknownKeys = true }
    private val prettyJson = Json { prettyPrint = true; ignoreUnknownKeys = true }

    fun serialize(parameters: EditParameters): String = json.encodeToString(parameters)

    fun deserialize(jsonString: String): Result<EditParameters> = runCatching {
        json.decodeFromString<EditParameters>(jsonString)
    }

    fun prettyPrint(parameters: EditParameters): String = prettyJson.encodeToString(parameters)
}
