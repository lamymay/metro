package com.rakukura.metrolab.system

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore

/**
 * The three system hand-offs Android actually lets a third-party app make: dial the
 * phone, compose mail in the default client, and hand off to the real Camera app for a
 * photo. Unlike iOS, `ACTION_DIAL` / `ACTION_SENDTO` / `ACTION_IMAGE_CAPTURE` genuinely
 * switch to the separate system app rather than presenting an in-process picker.
 */
object MetroSystemLauncher {

    /** `ACTION_DIAL` (not `ACTION_CALL`) opens the Phone app's dialer pre-filled and lets
     * the user press the call button themselves — no CALL_PHONE permission needed, and
     * nothing dials itself. */
    fun openPhoneDialer(activity: Activity, number: String = "18005550100") {
        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number"))
        if (intent.resolveActivity(activity.packageManager) != null) activity.startActivity(intent)
    }

    /** `ACTION_SENDTO` with a `mailto:` Uri opens the default mail client's compose
     * screen without needing any Intent extras or permissions. */
    fun openMailCompose(activity: Activity, to: String = "", subject: String = "") {
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:$to"))
        if (subject.isNotEmpty()) intent.putExtra(Intent.EXTRA_SUBJECT, subject)
        if (intent.resolveActivity(activity.packageManager) != null) activity.startActivity(intent)
    }

    fun cameraAvailable(activity: Activity): Boolean {
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        return intent.resolveActivity(activity.packageManager) != null
    }

    /** Hands off to the real Camera app; the result comes back to whichever activity
     * called this via `onActivityResult`/`ActivityResultLauncher` with [requestCode]. */
    fun openCamera(activity: Activity, requestCode: Int) {
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (intent.resolveActivity(activity.packageManager) != null) {
            activity.startActivityForResult(intent, requestCode)
        }
    }

    /** `ACTION_SENDTO` with an `smsto:` Uri opens the default Messages app's compose
     * screen, same shape as [openMailCompose]. */
    fun openMessaging(activity: Activity, number: String = "") {
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$number"))
        if (intent.resolveActivity(activity.packageManager) != null) activity.startActivity(intent)
    }

    /** A bare `geo:` Uri with no target app named. When more than one app can handle
     * it, Android's own disambiguation dialog is what shows — there is nothing extra
     * to build for that, an implicit intent with no default set does it natively. */
    fun openMaps(activity: Activity) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q="))
        if (intent.resolveActivity(activity.packageManager) != null) activity.startActivity(intent)
    }

    /** Opens the device's gallery/photos app on its main grid — `ACTION_MAIN` +
     * `CATEGORY_APP_GALLERY` targets the app the OS itself considers "the" Photos app,
     * rather than opening a generic image-picker chooser. */
    fun openPhotos(activity: Activity) {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_APP_GALLERY)
        if (intent.resolveActivity(activity.packageManager) != null) {
            activity.startActivity(intent)
        } else {
            val fallback = Intent(Intent.ACTION_VIEW, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            if (fallback.resolveActivity(activity.packageManager) != null) activity.startActivity(fallback)
        }
    }
}
