import io.realm.kotlin.Realm
import io.realm.kotlin.RealmConfiguration
import io.realm.kotlin.ext.query
import javax.inject.Singleton

@Singleton
class AnalyticsRepository {

    private val realm: Realm

    init {
        val config = RealmConfiguration.Builder(
            schema = setOf(FeatureTimeUsage::class)
        ).build()
        realm = Realm.open(config)
    }

    fun saveFeatureEntry(featureName: String): String {
        val featureUsage = FeatureTimeUsage().apply {
            this.featureName = featureName
            this.entryTimestamp = System.currentTimeMillis()
        }
        realm.writeBlocking {
            copyToRealm(featureUsage)
        }
        return featureUsage.id
    }

    fun saveFeatureExit(id: String) {
        realm.writeBlocking {
            val usage = query<FeatureTimeUsage>("id == $0", id).first().find()
            usage?.exitTimestamp = System.currentTimeMillis()
        }
    }
}
