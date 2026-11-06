# Data Source Proposals

## Proposal 1: Steam player activity vs. Twitch viewership (preferred)

**What it is:** We want to compare how many people are currently playing a PC game on Steam with how many are watching live streams of the same game on Twitch. By collecting both numbers at regular intervals, we could examine whether player activity and viewership rise and fall together and whether they follow similar daily or weekly patterns. We would choose a game with consistent activity on both platforms; *Stardew Valley* is our current example, not a final selection.

- **Content:** Steam provides the number of players currently connected to a game. Twitch provides live streams for a game, with a viewer count for each stream. We would record the game, collection time, Steam player count, and Twitch viewer counts (which can be summed for a game-wide estimate).
- **URLs:**
  - Steam: https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid=413150 (`413150` is *Stardew Valley*'s Steam app ID).
  - Twitch streams: https://api.twitch.tv/helix/streams?game_id=GAME_ID&first=100
  - Twitch game ID lookup: https://api.twitch.tv/helix/games?name=Stardew%20Valley
- **Update frequency:** These are live measurements that can change throughout the day. **Planned collection:** approximately once every two hours.
- **Expected sample size:** About **10–200 KB per collection** for one game, depending mostly on the number of Twitch streams and response pages. At 12 collections per day for 13 weeks, this would be roughly **11–220 MB**. These are preliminary estimates, to be checked with actual responses.
- **Key / password:** Steam does not require an API key for this endpoint. Twitch requires a free developer application, a Client ID, and an OAuth access token obtained using a Client Secret. Credentials would be kept outside the repository.
- **Data sample:** Shortened examples of the expected JSON response format (**illustrative values, not live observations**):

Steam:
```json
{
  "response": {
    "player_count": 45000,
    "result": 1
  }
}
```

Twitch (one stream shown):
```json
{
  "data": [
    {
      "user_name": "ExampleStreamer",
      "game_id": "GAME_ID",
      "game_name": "Stardew Valley",
      "viewer_count": 125,
      "started_at": "2026-11-05T12:00:00Z"
    }
  ],
  "pagination": {"cursor": "..."}
}
```

**Practical consideration:** Twitch reports viewers per stream, so totals require combining streams; results may span multiple pages (up to 100 streams per page). Steam players and Twitch viewers are different populations, so we would study patterns of association rather than assume one causes the other.

## Proposal 2: Promotions on protein-labeled products at Israeli supermarkets

**What it is:** We want to track how promotions on products marketed as high-protein, such as protein yogurts, bars, and snacks, change over time. We would preselect a small, fixed basket of protein-labeled products and use their unique product codes to automatically track their promotions over time. We would initially consider **Carrefour** as an example source and compare a small number of branches: how often these products are on promotion, how long promotions last, and whether offers differ between branches. If Carrefour's dataset is already being used by another group or proves unsuitable, we could use a similar public dataset from another chain, such as **Hazi Hinam** or **Shufersal**, instead.

- **Content:** Product names and codes, regular prices, promotion descriptions, promotion start/end dates, and branch identifiers. Price and promotion files would be used together to identify which selected products are on promotion.
- **URLs:**
  - Initial example — Carrefour public price-transparency portal: https://prices.carrefour.co.il/
  - Possible alternative — Hazi Hinam public price-file portal: https://shop.hazi-hinam.co.il/Prices
  - Possible alternative — Shufersal price-transparency portal: https://prices.shufersal.co.il/ 
  - These portals publish branch-level price and promotion information, commonly as compressed XML files (`.gz`). Relevant file categories include `PriceFull`, `PromoFull`, and store information, although exact availability and file details can vary by chain.
- **Update frequency:** The retailers publish updated price and promotion information regularly; full files are generally refreshed daily, with some changes appearing more frequently. **Planned collection:** approximately once a day.
- **Expected sample size:** For two branches, we estimate approximately 1–3 MB of compressed XML files per daily collection, or roughly 90–270 MB over 13 weeks. This estimate refers to the original supermarket files which contain information about many products. Our processed dataset would be much smaller, containing only information relevant to our selected protein products. Actual file sizes will be verified before implementation to ensure we stay within the project's 500 MB storage limit.
- **Key / password:** The listed portals provide public file listings without a paid subscription or private API key. Downloading automatically may require retrieving current download links. We would confirm scripted access before choosing an alternative chain.
- **Data sample:** Simplified example of the expected XML promotion format (**illustrative, not an actual advertised offer**):

```xml
<Promotion>
  <PromotionID>EXAMPLE-001</PromotionID>
  <PromotionDescription>מבצע על יוגורט חלבון</PromotionDescription>
  <PromotionStartDate>2026-11-05</PromotionStartDate>
  <PromotionEndDate>2026-11-11</PromotionEndDate>
  <Groups>
    <Group>
      <PromotionItems>
        <PromotionItem><ItemCode>7290000000000</ItemCode></PromotionItem>
      </PromotionItems>
    </Group>
  </Groups>
</Promotion>
```

**Practical consideration:** Price and promotion files are separate and must be matched by product code. Promotions take different forms (for example, multi-buy or club-member offers), so our initial focus would be on whether a product is on promotion, not necessarily calculating an exact percentage discount. We would choose one retailer after checking access and the course staff's approval.

## Our ranking

1. **Steam vs. Twitch — first choice.** The data changes frequently, is returned as JSON, and offers a clear comparison between two independent sources.
2. **Protein-product supermarket promotions — second choice.** It has a useful time-based comparison and publicly published data, but compressed XML files and product/promotion matching may take more work.
