import io.realm.kotlin.types.RealmObject
import io.realm.kotlin.types.annotations.PrimaryKey
import java.util.UUID

class FeatureTimeUsage : RealmObject {
    @PrimaryKey
    var id: String = UUID.randomUUID().toString()
    var featureName: String = ""
    var entryTimestamp: Long = 0L
    var exitTimestamp: Long = 0L

    val duration: Long
        get() = exitTimestamp - entryTimestamp
}
