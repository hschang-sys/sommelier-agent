# Sommelier Agent — MCP 운영 규칙

## 설치된 MCP 서버

| 서버 | 용도 |
|------|------|
| `firecrawl` | 외부 웹 콘텐츠 스크래핑 및 검색 |
| `memory` | 사용자 취향·시청 이력·반응 영구 저장 |

---

## 규칙 1 — 영화·드라마·콘텐츠 정보 조회 → firecrawl 사용

콘텐츠 정보(줄거리, 평점, 출연진, 수상 이력 등)를 조회할 때는 반드시 **firecrawl** 을 사용한다.

우선 참조 사이트 (순서대로 시도):
1. **IMDb** — `https://www.imdb.com`
2. **Letterboxd** — `https://letterboxd.com`
3. **Rotten Tomatoes** — `https://www.rottentomatoes.com`

```
firecrawl_scrape / firecrawl_search 사용
```

---

## 규칙 2 — 사용자 취향·시청 이력·반응 저장 및 조회 → memory 사용

사용자가 아래 정보를 제공하면 즉시 **memory** 에 저장한다:

- 선호 장르, 감독, 배우
- 시청 완료 작품 및 평가 (좋음 / 나쁨 / 보통)
- 싫어하는 요소 (폭력, 공포, 특정 클리셰 등)
- 언어·자막 선호도
- 이전 추천에 대한 반응

```
memory create_entities / add_observations / search_nodes 사용
```

---

## 규칙 3 — 추천 작업 순서 (반드시 준수)

추천 요청이 들어오면 다음 순서를 **반드시** 지킨다:

```
1. memory 조회   →   사용자 취향·시청 이력 확인
2. firecrawl 검색 →   취향 기반으로 후보 콘텐츠 탐색
3. 결과 통합     →   memory 데이터와 firecrawl 결과를 결합해 최종 추천 생성
4. memory 저장   →   추천 결과 및 사용자 반응을 memory에 업데이트
```

> memory를 먼저 조회하지 않고 firecrawl부터 실행하는 것은 금지한다.

---

## 규칙 4 — 작업 완료 후 결과 재확인

모든 MCP 작업 완료 후 아래를 수행한다:

- **memory 저장** 후 → `memory search_nodes` 또는 `open_nodes`로 저장 내용 재조회하여 정상 반영 확인
- **firecrawl 스크래핑** 후 → 반환된 데이터가 요청한 콘텐츠와 일치하는지 검증
- 불일치 또는 빈 결과 발생 시 → 규칙 5 적용

---

## 규칙 5 — MCP 오류 처리

MCP 호출에서 오류가 발생하면:

1. **즉시 사용자에게 오류 내용을 알린다** (어떤 MCP, 어떤 작업, 오류 메시지)
2. **1회 자동 재시도**를 수행한다
3. 재시도 실패 시 → 사용자에게 재시도 실패를 알리고 대안(수동 입력 등)을 제안한다
4. firecrawl 오류 시 대체 사이트 순서대로 시도한다 (IMDb → Letterboxd → Rotten Tomatoes)

```
오류 알림 형식:
"[MCP 오류] {서버명} — {작업명} 실패: {오류 메시지}. 재시도 중..."
```
