require Logger

Logger.info "[start] #{HexFaktor.EmailPublisher.now}"

HexFaktor.EmailPublisher.send_weekly_emails()

Logger.info " [done] #{HexFaktor.EmailPublisher.now}"
