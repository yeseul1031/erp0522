## ADR-DOM-0002 sourcing_case의 계약 범위 정본은 sc가 가진다

- 결정:
    - `sourcing_cases`는 정확히 하나의 계약 범위를 담당한다.
    - 계약 범위는 `order_line 전체` 또는 `order_line + 특정 order_line_override 1건`이다.
    - 이를 위해 `sourcing_cases.sc_ol_sn`은 필수, `sourcing_cases.sc_olo_sn`은 선택으로 둔다.
- 이유:
    - 수급 케이스(sc)가 무엇을 담당하는지 헤더에서 바로 해석 가능해야 한다.
    - `sourcing_case_lines`는 해당 sc 내부 실행 분해 라인이며, 계약 범위를 새로 정의하지 않는다.
    - `scl_ol_sn` / `scl_olo_sn`은 복잡한 실행 구조에서도 화면/조회/집계에서 ol / olo를 빠르게 함께 보여주기 위한 보조 연결이다.
- 기각:
    - 계약 범위를 sc가 직접 가지지 않고 scl 집합으로만 해석하는 방식
      — 헤더만으로 담당 범위를 알 수 없고, 앱/UI가 항상 추론해야 하므로 운영 해석이 불안정해진다.