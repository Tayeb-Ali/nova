package sd.adaa.nova.runtime

/**
 * Static metadata for a managed runtime (task.md §4 §13).
 * New runtimes are added here only — no architecture change (plan.md §29 rule 8).
 */
data class RuntimeDefinition(
    val id: String,
    val displayName: String,
    val executable: String,
    val packageName: String,
    val aliases: List<String>,
)

object RuntimeRegistry {
    val all: List<RuntimeDefinition> = listOf(
        RuntimeDefinition("php", "PHP", "php", "php", listOf("php")),
        RuntimeDefinition("node", "Node.js", "node", "nodejs", listOf("node", "npm", "npx")),
        RuntimeDefinition("python", "Python", "python3", "python", listOf("python", "python3", "pip")),
        RuntimeDefinition("git", "Git", "git", "git", listOf("git")),
        RuntimeDefinition("composer", "Composer", "composer", "composer", listOf("composer")),
        RuntimeDefinition("openssh", "OpenSSH", "ssh", "openssh", listOf("ssh", "scp", "sftp")),
    )

    fun get(id: String): RuntimeDefinition? = all.firstOrNull { it.id == id }
}