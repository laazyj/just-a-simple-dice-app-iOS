# Measuring the App Store listing

Record a baseline before changing anything that affects discovery (price,
name, subtitle, keywords, screenshots), then compare the same numbers
4–6 weeks after the change.

## 1. Downloads, proceeds, ratings, search rank

```sh
ASC_KEY_ID=... ASC_ISSUER_ID=... ASC_KEY_PATH=AuthKey_XXXX.p8 \
ASC_VENDOR_NUMBER=... bundle exec ruby scripts/app-stats.rb 28 > baseline.md
```

- The API key needs Sales and Trends access.
- The vendor number is under App Store Connect → Payments and Financial
  Reports (top left).

Run it on your own machine: sales figures are private, and logs and
artifacts of Actions runs on a public repo are not.

## 2. Discovery funnel (App Store Connect → Analytics)

The API doesn't serve these numbers until an analytics report request has
been running for a while, so copy them from the Analytics dashboard. Use
the last 28 days, all territories:

| Metric | Where | Baseline | After |
| --- | --- | ---: | ---: |
| Impressions (unique devices) | Metrics → Impressions | | |
| Product page views (unique devices) | Metrics → Product Page Views | | |
| Conversion rate | Overview | | |
| First-time downloads | Metrics → First-Time Downloads | | |
| Share from App Store Search | Sources → App Store Search | | |
| Share from App Store Browse | Sources → App Store Browse | | |
| Rank in category (if charting) | Overview / Top Charts | | |

Keep filled-in copies out of this public repo unless you're happy to
publish them.
