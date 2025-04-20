import androidx.lifecycle.ViewModel
import com.example.uni_matketplace_kotlin.data.repositories.SessionLogRepository

class SessionViewModel : ViewModel() {
    fun logEvent(event: String, section: String) {
        SessionLogRepository.logSessionEvent(event, section)
    }
}
