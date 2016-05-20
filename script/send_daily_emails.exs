require Logger

Logger.info "[start] #{HexFaktor.EmailPublisher.now}"

HexFaktor.EmailPublisher.send_daily_emails()

Logger.info " [done] #{HexFaktor.EmailPublisher.now}"
