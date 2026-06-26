package com.enaykumar.qagenie

import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.appcheck.AppCheckProvider
import com.google.firebase.appcheck.AppCheckProviderFactory
import com.google.firebase.appcheck.AppCheckToken

class FakeAppCheckToken : AppCheckToken() {
  override fun getToken(): String = "dev-fake-token"
  override fun getExpireTimeMillis(): Long = System.currentTimeMillis() + 3_600_000L
}

class DevAppCheckProvider : AppCheckProvider {
  override fun getToken(): Task<AppCheckToken> = Tasks.forResult(FakeAppCheckToken())
}

class DevAppCheckProviderFactory : AppCheckProviderFactory {
  override fun create(app: FirebaseApp): AppCheckProvider = DevAppCheckProvider()
}
