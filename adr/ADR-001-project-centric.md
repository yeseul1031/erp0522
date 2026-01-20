# ADR-001: Project-centric Architecture

## Status
Accepted

## Context
ERP 설계에서 조직/부서 중심으로 갈지, 프로젝트 중심으로 갈지 결정이 필요했다.

## Decision
Balhea ERP의 모든 업무와 데이터의 최상위 단위를 **프로젝트(Project)** 로 정의한다.

## Consequences
- 담당자 변경 시 영향 범위가 최소화된다.
- 조직 개편이 ERP 구조에 직접 영향을 주지 않는다.
- 리포트와 권한은 프로젝트 집합 기준으로 구성된다.
