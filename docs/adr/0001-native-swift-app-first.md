# Native Swift app for iPhone and iPad first, no website

The app is used mostly on an iPhone during the day, sometimes on an iPad, and rarely on a laptop, for one year in China, often with weak internet. We build a native Swift app with iCloud sync, because it is the only option where offline use, iPhone–iPad sync and reminders all work in China without a VPN.

## Considered Options

- **Flutter**: the student already knows it, but iCloud sync is awkward and the usual sync backend (Firebase) is blocked in China.
- **Website**: free and runs anywhere, but sync needs a server, and hosting outside China is often slow or blocked there.
- **Both app and website**: doubles the build work and forces a custom server to share data. Deferred: a website may be added later only if a real need appears.
