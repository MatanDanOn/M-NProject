# Data Source Proposals

## Proposal 1: Steam player activity vs. Twitch viewership (preferred)

**The Idea:** We want to compare how many people are currently playing a PC game on Steam with how many are watching live streams of the same game on Twitch. By collecting both numbers at regular intervals, we could examine whether player activity and viewership rise and fall together and whether they follow similar daily or weekly patterns. We would choose a game with consistent activity on both platforms, *Stardew Valley* is our current example, not a final selection.

- **Content:** Steam provides the number of players currently connected to a game. Twitch provides live streams for a game, with a viewer count for each stream. We would record the game, collection time, Steam player count, and Twitch viewer counts (which can be summed for a game-wide estimate).
- **URLs:**
  - Steam: https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid=413150 (`413150` is *Stardew Valley*'s Steam app ID).
  - Twitch streams: https://api.twitch.tv/helix/streams?game_id=490744&first=100 (`490744` was verified as *Stardew Valley*'s Twitch game ID).
  - Twitch game ID lookup: https://api.twitch.tv/helix/games?name=Stardew%20Valley
- **Update frequency:** These are live measurements that can change throughout the day. **Planned collection:** approximately once every two hours.
- **Expected sample size:** The authenticated sample below contained **31,801 bytes** of Twitch stream responses across two requests (including the final empty page) and **46 bytes** from Steam: **31,847 bytes per collection**, approximately **31.85 KB**. At 12 collections per day for 13 weeks (1,092 collections), similar responses would total **34,776,924 bytes**, approximately **34.8 MB before compression**. The one-time game-ID lookup was another **157 bytes**. A provisional threefold allowance would be about **104.3 MB** for response bodies, leaving room below the project's 500 MB limit for metadata and derived outputs. This allowance is a planning assumption, not a measured maximum as one sample cannot establish the peak number of streams or guarantee the final storage requirement. 
- **Key / password:** Steam does not require an API key for this endpoint. Twitch requires a free developer application, a Client ID, and an OAuth access token obtained using a Client Secret. Credentials would be kept outside the repository.
- **Data sample:** Actual authenticated Twitch responses and a Steam response collected on **2026-11-06 between 14:14:25 and 14:14:27 UTC**. These are real observations - retrieval times are not guaranteed exact measurement times, and Steam may cache its responses.

Steam response, for `appid=413150`:

```json
{
  "response": {
    "player_count": 73996,
    "result": 1
  }
}
```

Twitch: selected fields from the first returned stream record, for `game_id=490744`. Other fields and records are omitted from this excerpt, the measured size above refers to the full response bodies, not this shortened example.

```json
{
  "data": [
    {
      "id": "319290086886",
      "user_name": "DaWhamBam",
      "game_id": "490744",
      "game_name": "Stardew Valley",
      "viewer_count": 39,
      "started_at": "2026-11-06T12:56:57Z"
    }
  ]
}
```

**Collection check:** The first Twitch page returned **63 streams** in **31,774 bytes** and supplied a pagination cursor. Following that cursor returned an empty final page of **27 bytes**, with no further cursor. There were **63 unique stream IDs**, summing their reported `viewer_count` values gave **236 viewers**. Steam reported **73,996 players** in its response fetched during the same collection window. The viewer sum is an estimate across sequential requests, not an atomic snapshot or a count of unique people. One collection demonstrates access and sample size, not a relationship between the two populations.

**Authentication tested:** A dedicated confidential application was registered and its app access token was validated before calling Get Games and Get Streams. The `client_credentials` flow was used to read public data without requesting channel-management permissions. Client Secret and tokens are kept outside the repository and are not part of the data samples.

**Practical consideration:** Twitch reports viewers per stream, so totals require combining streams and following pagination (up to 100 streams per page). Because streams can change between page requests, duplicate stream IDs must be handled when aggregating. Steam players and Twitch viewers are different populations, so we would study patterns of association rather than assume one causes the other. API details: [Get Games](https://dev.twitch.tv/docs/api/reference/#get-games), [Get Streams](https://dev.twitch.tv/docs/api/reference/#get-streams), and [app access tokens](https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#client-credentials-grant-flow).

## Proposal 2: Promotions on protein-labeled products at Israeli supermarkets

**What it is:** We want to track how promotions on products marketed as high-protein, such as protein yogurts, bars, and snacks, change over time. We would preselect a small, fixed basket of protein-labeled products and use their unique product codes to automatically track their promotions over time. We would initially consider **Carrefour** as an example source and compare a small number of branches: how often these products are on promotion, how long promotions last, and whether offers differ between branches. If Carrefour's dataset is already being used by another group or proves unsuitable, we could use a similar public dataset from another chain, such as **Hazi Hinam** or **Shufersal**, instead.

- **Content:** Product names and codes, regular prices, promotion descriptions, promotion start/end dates, and branch identifiers. Price and promotion files would be used together to identify which selected products are on promotion.
- **URLs:**
  - Initial example — Carrefour public price-transparency portal: https://prices.carrefour.co.il/
  - Possible alternative — Hazi Hinam public price-file portal: https://shop.hazi-hinam.co.il/Prices
  - Possible alternative — Shufersal price-transparency portal: https://prices.shufersal.co.il/ 
  - These portals publish branch-level price and promotion information, commonly as compressed XML files (`.gz`). Relevant file categories include `PriceFull`, `PromoFull`, and store information, although exact availability and file details can vary by chain.
- **Update frequency:** The Carrefour listing checked on 2026-11-06 contained timestamped `PriceFull` and `PromoFull` files and multiple incremental `Price` updates during the day. **Planned collection:** approximately once a day, however the longer-term publication schedule would be verified before implementation.
- **Expected sample size:** The four downloaded full files (prices and promotions for branches 010 and 009) total **2,300,619 compressed bytes**, approximately **2.30 MB per daily collection**. At one collection a day for 13 weeks (91 days), this would be approximately **209.4 MB**, assuming similar sizes. This is below the project's 500 MB limit, but future growth and other stored files must also be monitored. These files include many products, leading to a much smaller processed protein-product dataset.
- **Key / password:** Carrefour's listing and the four sample files were retrieved without a login, subscription, or API key. Download links contain the publication date and filename, so collection must obtain current links from the listing. Access to the alternative chains has not been tested.
- **Data sample:** Actual price and promotion files downloaded on **2026-11-06 at approximately 13:53 UTC**, from Carrefour's public portal, without credentials. The sample below is from branch **010**, listed by the portal as Carrefour Hyper Kfar Saba. The portal's product name is preserved as supplied, including its abbreviation. These are selected XML fields from the downloaded files, retaining their original hierarchy and values. Other fields, products, and promotion items are omitted.

Files downloaded to check access and compressed sample sizes:

| Branch | Source file | Compressed bytes |
|---|---|---:|
| 010 | [PriceFull](https://prices.carrefour.co.il/20261106/PriceFull7290055700007-001-010-20261106-051009.gz) | 883,097 |
| 010 | [PromoFull](https://prices.carrefour.co.il/20261106/PromoFull7290055700007-001-010-20261106-051121.gz) | 238,210 |
| 009 | [PriceFull](https://prices.carrefour.co.il/20261106/PriceFull7290055700007-001-009-20261106-051002.gz) | 968,182 |
| 009 | [PromoFull](https://prices.carrefour.co.il/20261106/PromoFull7290055700007-001-009-20261106-051055.gz) | 211,130 |

Price-file excerpt:

```xml
<Root>
  <ChainID>7290055700007</ChainID>
  <SubChainID>001</SubChainID>
  <StoreID>010</StoreID>
  <Items>
    <Item>
      <PriceUpdateTime>2025-06-03T08:29:14.000</PriceUpdateTime>
      <ItemCode>7290116934020</ItemCode>
      <ItemName>יוגורט חלבון גו 20 ג</ItemName>
      <Quantity>200.00</Quantity>
      <ItemPrice>6.50</ItemPrice>
    </Item>
  </Items>
</Root>
```

Promotion-file excerpt for the same product:

```xml
<Root>
  <ChainID>7290055700007</ChainID>
  <SubChainID>001</SubChainID>
  <StoreID>010</StoreID>
  <Promotions>
    <Promotion>
      <PromotionID>0011459283</PromotionID>
      <PromotionDescription>יוגורט גו סמיך 0% יופלה עד 200 גרם</PromotionDescription>
      <PromotionStartDateTime>2026-11-02T00:00:00.000</PromotionStartDateTime>
      <PromotionEndDateTime>2026-12-11T23:59:00.000</PromotionEndDateTime>
      <ClubID>0</ClubID>
      <Groups>
        <Group>
          <GroupID>1</GroupID>
          <PromotionItems>
            <PromotionItem>
              <ItemCode>7290116934020</ItemCode>
              <RewardType>10</RewardType>
              <MinQty>4</MinQty>
              <DiscountedPrice>20.90</DiscountedPrice>
            </PromotionItem>
          </PromotionItems>
        </Group>
      </Groups>
    </Promotion>
  </Promotions>
</Root>
```

The same `ItemCode` (`7290116934020`) appears in both files, demonstrating how a protein-labeled product can be matched to a promotion. `ItemPrice` is the listed regular price; `MinQty` and `DiscountedPrice` belong to a multi-buy promotion and must not be interpreted as a single-unit promotional price. Source promotion timestamps have no timezone offset; the UTC time above records retrieval only.

**Practical consideration:** Price and promotion files are separate and must be matched by product code. Promotions take different forms (for example, multi-buy or club-member offers), so our initial focus would be on whether a product is on promotion, not necessarily calculating an exact percentage discount. We would choose one retailer after checking access and the course staff's approval.

## Our ranking

1. **Steam vs. Twitch — first choice.** The data changes frequently, is returned as JSON, and offers a clear comparison between two independent sources.
2. **Protein-product supermarket promotions — second choice.** It has a useful time-based comparison and publicly published data, but compressed XML files and product/promotion matching may take more work.
