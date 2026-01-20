# ERP Data Guide

이 저장소는 **ERP 데이터 구조(DDL)와 운영/설계 문서의 정본(Source of Truth)** 을 관리한다.
서비스 UI, IA, Wireframe이 아직 확정되지 않은 상태에서 **데이터 중심으로 먼저 설계**하는 것을 전제로 한다.

---

## 1. 이 저장소의 역할

- ERP 데이터 모델(DDL)의 **현재 정본** 관리
- 데이터 설계의 **운영 가이드 / 설계 맥락 / 결정 기록** 관리
- 외부 설계 도구와의 협업 시 **맥락 손실 방지용 기준점**

---

## 2. 디렉토리 구조 규칙 (정본)

```text
erp-data-guide/
├── ddl/        # DDL 전용 (CREATE TABLE 등 스키마 정의)
├── docs/       # 운영/설계 문서
├── adr/        # Architecture Decision Records (ADR)
└── README.md   # 이 문서
```

---

## 3. DDL 파일 네이밍 규칙

- DDL 파일은 반드시 `erp_*_schema.sql` 형식을 사용한다.
- 파일명에는 **버전을 포함하지 않는다**.
- 예시:
  - `erp_core_schema.sql`
  - `erp_finance_schema.sql`
  - `erp_logistics_schema.sql`

> `.sql` 파일 중 `*_schema.sql` 이 아닌 파일은  
> 쿼리, 시드, 유틸 스크립트로 간주한다.

---

## 4. 파일별 버전 관리 원칙

- 전체 저장소 버전을 하나로 묶지 않는다.
- **파일 단위 버전(file_version)** 을 사용한다.
- 버전은 Git 태그나 파일명에 넣지 않고,
  **각 파일 헤더에 명시**한다.

### DDL 헤더 예시
```sql
-- Project : ERP Data Guide
-- Repo    : erp-data-guide
-- File    : ddl/erp_core_schema.sql
-- Version : 1.0.3
-- Date    : 2026-01-20
-- Summary : Documents hub 통합 및 문서 코드 표준 확장
```

### Markdown 헤더 예시
```md
---
project: "ERP Data Guide"
repo: "erp-data-guide"
file: "docs/operations-guide.md"
version: "1.0.2"
date: "2026-01-20"
summary: "문서 허브 운영 규칙 및 결정 트리 보강"
---
```

---

## 5. 변경 시 작업 규칙

1. 수정 대상 파일을 선택한다.
2. 해당 파일의 헤더에서:
   - Version 증가 (patch 기준)
   - Date 갱신
   - Summary에 변경 요약 작성
3. Git 커밋 메시지에 변경 파일/의도를 남긴다.

> CHANGELOG.md는 사용하지 않는다.  
> 변경 이력은 Git과 파일 헤더가 담당한다.

---

## 6. ADR(Architecture Decision Record) 운영 원칙

- ADR은 **되돌리기 싫은 핵심 결정**만 기록한다.
- 모든 ADR은 `adr/ADR-XXX-*.md` 형식을 따른다.
- 설계가 변경될 경우 기존 ADR은 삭제하지 않고:
  - `Status: Superseded` 로 표시한다.

---

## 7. 새로운 대화를 시작할 때 (중요)

아래 메시지를 그대로 복사해 새 대화의 첫 메시지로 사용한다.

```text
ERP Data Guide 저장소의 정본을 기반으로 설계를 이어서 진행하고 싶다.

이 저장소에는 다음이 포함되어 있다:
- DDL (erp_*_schema.sql)
- 운영 가이드 / 설계 맥락 문서
- ADR(Architecture Decision Records)

이미 결정된 사항(Project-centric, cost≠payment, documents hub 등)은 재논의하지 말고,
새 요구사항이나 변경이 필요한 부분만 제안해 달라.
```

---

## 8. 문서 간 역할 요약

- `ddl/` : 현재 데이터 구조의 정본
- `docs/operations-guide.md` : 실제 입력/운영 기준
- `docs/design-and-scenarios.md` : 설계 맥락과 전체 흐름
- `docs/design-decisions-log.md` : 결정 요약(ADR 인덱스)
- `adr/` : 결정의 공식 기록

이 README는 **현재 설계 스냅샷을 설명하는 지도**이며,
설계 진화에 따라 갱신될 수 있다.
