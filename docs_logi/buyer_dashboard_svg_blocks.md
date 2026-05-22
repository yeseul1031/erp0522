# Buyer Dashboard SVGs

아래는 피그마에 바로 복사하여 사용할 수 있는 화면 상태별 4개의 SVG 코드입니다. 그룹 태그(`<g id="...">`)가 적용되었으며 색상과 여백을 명세서 기준에 맞추었습니다.

## 화면 A (홈 - 기본 화면)
```xml
<svg width="1440" height="960" viewBox="0 0 1440 960" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="1440" height="960" fill="#F0F2F5"/>

<g id="GNB">
  <rect width="1440" height="60" fill="#FFFFFF" stroke="#E8E8E8"/>
  <text x="24" y="36" fill="#1F1F1F" font-family="Inter" font-size="20" font-weight="900"><tspan fill="#1677FF">NEO</tspan> BH</text>
  <text x="120" y="36" fill="#8C8C8C" font-family="Inter" font-size="14">Home</text>
  <text x="500" y="36" fill="#1F1F1F" font-family="Inter" font-size="14" font-weight="bold">입출고관리</text>
  <rect x="496" y="58" width="65" height="2" fill="#1F1F1F"/>
  <circle cx="1320" cy="30" r="14" fill="#1677FF"/>
  <text x="1342" y="35" fill="#595959" font-family="Inter" font-size="13" font-weight="500">김지원님 ▼</text>
</g>

<g id="Sidebar">
  <rect y="60" width="260" height="900" fill="#FFFFFF" stroke="#E8E8E8"/>
  <text x="40" y="98" fill="#1F1F1F" font-family="Inter" font-size="14" font-weight="bold">진행중인 프로젝트</text>
  <rect x="16" y="120" width="228" height="36" rx="4" fill="#FFFFFF" stroke="#D9D9D9"/>
  <text x="45" y="142" fill="#BFBFBF" font-family="Inter" font-size="13">프로젝트명 검색</text>
  <rect x="16" y="170" width="228" height="60" rx="8" fill="#0F172A"/>
  <text x="28" y="195" fill="#FFFFFF" font-family="Inter" font-size="13" font-weight="500">강력세척제 외 72종</text>
  <text x="175" y="215" fill="#1677FF" font-family="Inter" font-size="11" font-weight="bold">100% 완료</text>
</g>

<g id="Main_Content">
  <g id="Header_Box">
    <rect x="284" y="84" width="1132" height="84" rx="12" fill="#FFFFFF" stroke="#E8E8E8"/>
    <rect x="304" y="106" width="40" height="40" rx="8" fill="#1677FF"/>
    <text x="356" y="125" fill="#1F1F1F" font-family="Inter" font-size="20" font-weight="bold">입고 처리</text>
    <text x="356" y="145" fill="#8C8C8C" font-family="Inter" font-size="12">SCR-INB-001</text>
    
    <text x="584" y="118" fill="#8C8C8C" font-family="Inter" font-size="11">거래처명으로 검색</text>
    <rect x="584" y="126" width="240" height="32" rx="4" fill="#FFFFFF" stroke="#D9D9D9"/>
    <text x="614" y="146" fill="#BFBFBF" font-family="Inter" font-size="13">거래처명 검색 (예: 삼성, LG...)</text>
    
    <rect x="1260" y="110" width="136" height="32" rx="4" fill="#FFFFFF" stroke="#D9D9D9"/>
    <text x="1292" y="130" fill="#595959" font-family="Inter" font-size="13" font-weight="500">엑셀 일괄 다운로드</text>
  </g>
  
  <g id="Summary_Cards">
    <rect x="284" y="192" width="365" height="84" rx="8" fill="#FFFFFF" stroke="#E8E8E8"/>
    <rect x="284" y="192" width="4" height="84" fill="#CF1322" rx="2"/>
    <text x="304" y="222" fill="#8C8C8C" font-family="Inter" font-size="12" font-weight="600">미입고 지연 품목</text>
    <text x="304" y="256" fill="#CF1322" font-family="Inter" font-size="24" font-weight="bold">1 <tspan fill="#8C8C8C" font-size="14" font-weight="normal">건</tspan></text>
    
    <rect x="665" y="192" width="365" height="84" rx="8" fill="#FFFFFF" stroke="#E8E8E8"/>
    <rect x="665" y="192" width="4" height="84" fill="#1677FF" rx="2"/>
    <text x="685" y="222" fill="#8C8C8C" font-family="Inter" font-size="12" font-weight="600">오늘 입고 예정</text>
    <text x="685" y="256" fill="#1677FF" font-family="Inter" font-size="24" font-weight="bold">6 <tspan fill="#8C8C8C" font-size="14" font-weight="normal">품목</tspan></text>
    
    <rect x="1046" y="192" width="370" height="84" rx="8" fill="#FFFFFF" stroke="#E8E8E8"/>
    <rect x="1046" y="192" width="4" height="84" fill="#52C41A" rx="2"/>
    <text x="1066" y="222" fill="#8C8C8C" font-family="Inter" font-size="12" font-weight="600">이번 주 출고 예정</text>
    <text x="1066" y="256" fill="#52C41A" font-family="Inter" font-size="24" font-weight="bold">2 <tspan fill="#8C8C8C" font-size="14" font-weight="normal">품목</tspan></text>
  </g>
  
  <g id="Grid">
    <rect x="284" y="300" width="1132" height="636" rx="8" fill="#FFFFFF" stroke="#E8E8E8"/>
    <text x="800" y="600" fill="#BFBFBF" font-family="Inter" font-size="16" text-anchor="middle">여기에 그리드 내용이 표시됩니다</text>
  </g>
</g>
</svg>
```

## 화면 B (사이드바 접힘 - Slim Text Mode)
```xml
<svg width="1440" height="960" viewBox="0 0 1440 960" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="1440" height="960" fill="#F0F2F5"/>

<g id="GNB">
  <rect width="1440" height="60" fill="#FFFFFF" stroke="#E8E8E8"/>
  <text x="24" y="36" fill="#1F1F1F" font-family="Inter" font-size="20" font-weight="900"><tspan fill="#1677FF">NEO</tspan> BH</text>
  <text x="120" y="36" fill="#8C8C8C" font-family="Inter" font-size="14">Home</text>
  <text x="500" y="36" fill="#1F1F1F" font-family="Inter" font-size="14" font-weight="bold">입출고관리</text>
  <rect x="496" y="58" width="65" height="2" fill="#1F1F1F"/>
  <circle cx="1320" cy="30" r="14" fill="#1677FF"/>
  <text x="1342" y="35" fill="#595959" font-family="Inter" font-size="13" font-weight="500">김지원님 ▼</text>
</g>

<g id="Sidebar_Closed">
  <rect y="60" width="52" height="900" fill="#FFFFFF" stroke="#E8E8E8"/>
  <!-- Slim text mode -->
  <text x="32" y="140" fill="#1F1F1F" font-family="Inter" font-size="13" font-weight="bold" transform="rotate(90 32 140)" letter-spacing="4">진행중인 프로젝트</text>
</g>

<g id="Main_Content">
  <g id="Header_Box">
    <rect x="76" y="84" width="1340" height="84" rx="12" fill="#FFFFFF" stroke="#E8E8E8"/>
    <rect x="96" y="106" width="40" height="40" rx="8" fill="#1677FF"/>
    <text x="148" y="125" fill="#1F1F1F" font-family="Inter" font-size="20" font-weight="bold">입고 처리</text>
    <text x="148" y="145" fill="#8C8C8C" font-family="Inter" font-size="12">SCR-INB-001</text>
    
    <text x="376" y="118" fill="#8C8C8C" font-family="Inter" font-size="11">거래처명으로 검색</text>
    <rect x="376" y="126" width="240" height="32" rx="4" fill="#FFFFFF" stroke="#D9D9D9"/>
    <text x="406" y="146" fill="#BFBFBF" font-family="Inter" font-size="13">거래처명 검색 (예: 삼성, LG...)</text>
    
    <rect x="1260" y="110" width="136" height="32" rx="4" fill="#FFFFFF" stroke="#D9D9D9"/>
    <text x="1292" y="130" fill="#595959" font-family="Inter" font-size="13" font-weight="500">엑셀 일괄 다운로드</text>
  </g>
  
  <g id="Summary_Cards">
    <rect x="76" y="192" width="435" height="84" rx="8" fill="#FFFFFF" stroke="#E8E8E8"/>
    <rect x="76" y="192" width="4" height="84" fill="#CF1322" rx="2"/>
    <text x="96" y="222" fill="#8C8C8C" font-family="Inter" font-size="12" font-weight="600">미입고 지연 품목</text>
    <text x="96" y="256" fill="#CF1322" font-family="Inter" font-size="24" font-weight="bold">1 <tspan fill="#8C8C8C" font-size="14" font-weight="normal">건</tspan></text>
    
    <rect x="527" y="192" width="435" height="84" rx="8" fill="#FFFFFF" stroke="#E8E8E8"/>
    <rect x="527" y="192" width="4" height="84" fill="#1677FF" rx="2"/>
    <text x="547" y="222" fill="#8C8C8C" font-family="Inter" font-size="12" font-weight="600">오늘 입고 예정</text>
    <text x="547" y="256" fill="#1677FF" font-family="Inter" font-size="24" font-weight="bold">6 <tspan fill="#8C8C8C" font-size="14" font-weight="normal">품목</tspan></text>
    
    <rect x="978" y="192" width="438" height="84" rx="8" fill="#FFFFFF" stroke="#E8E8E8"/>
    <rect x="978" y="192" width="4" height="84" fill="#52C41A" rx="2"/>
    <text x="998" y="222" fill="#8C8C8C" font-family="Inter" font-size="12" font-weight="600">이번 주 출고 예정</text>
    <text x="998" y="256" fill="#52C41A" font-family="Inter" font-size="24" font-weight="bold">2 <tspan fill="#8C8C8C" font-size="14" font-weight="normal">품목</tspan></text>
  </g>
  
  <g id="Grid">
    <rect x="76" y="300" width="1340" height="636" rx="8" fill="#FFFFFF" stroke="#E8E8E8"/>
    <text x="746" y="600" fill="#BFBFBF" font-family="Inter" font-size="16" text-anchor="middle">폭이 더 넓어진 그리드 영역</text>
  </g>
</g>
</svg>
```

## 화면 C (프로젝트 검색 - 리스트 필터링)
```xml
<svg width="1440" height="960" viewBox="0 0 1440 960" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="1440" height="960" fill="#F0F2F5"/>

<g id="Sidebar">
  <rect y="60" width="260" height="900" fill="#FFFFFF" stroke="#E8E8E8"/>
  <text x="40" y="98" fill="#1F1F1F" font-family="Inter" font-size="14" font-weight="bold">진행중인 프로젝트</text>
  <rect x="16" y="120" width="228" height="36" rx="4" fill="#FFFFFF" stroke="#1677FF"/>
  <text x="45" y="142" fill="#1F1F1F" font-family="Inter" font-size="13">하수처리장</text>
  <line x1="110" y1="130" x2="110" y2="148" stroke="#1677FF" stroke-width="1.5"/>
  
  <rect x="16" y="170" width="228" height="60" rx="8" fill="#0F172A"/>
  <text x="28" y="195" fill="#FFFFFF" font-family="Inter" font-size="13" font-weight="500">하수처리장 C동 증설 관급자재</text>
  <text x="175" y="215" fill="#1677FF" font-family="Inter" font-size="11" font-weight="bold">20% 완료</text>
</g>

<!-- Main content same as A (omitted for brevity) -->
<g id="Main_Content">
  <rect x="284" y="84" width="1132" height="852" rx="12" fill="#FFFFFF" stroke="#E8E8E8"/>
  <text x="850" y="510" fill="#BFBFBF" font-family="Inter" font-size="24" text-anchor="middle">하수처리장 상세 내역</text>
</g>
</svg>
```

## 화면 D (거래처 검색 - 결과 없음 Empty State)
```xml
<svg width="1440" height="960" viewBox="0 0 1440 960" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="1440" height="960" fill="#F0F2F5"/>

<g id="Sidebar">
  <rect y="60" width="260" height="900" fill="#FFFFFF" stroke="#E8E8E8"/>
  <!-- Sidebar list... -->
</g>

<g id="Main_Content">
  <g id="Header_Box">
    <rect x="284" y="84" width="1132" height="84" rx="12" fill="#FFFFFF" stroke="#E8E8E8"/>
    <!-- Vendor Search Input with Query -->
    <text x="584" y="118" fill="#8C8C8C" font-family="Inter" font-size="11">거래처명으로 검색</text>
    <rect x="584" y="126" width="240" height="32" rx="4" fill="#FFFFFF" stroke="#1677FF"/>
    <text x="614" y="146" fill="#1F1F1F" font-family="Inter" font-size="13">애플코리아</text>
  </g>
  
  <g id="Empty_State">
    <rect x="284" y="300" width="1132" height="636" rx="8" fill="#FFFFFF" stroke="#E8E8E8"/>
    <text x="850" y="560" fill="#1F1F1F" font-family="Inter" font-size="20" font-weight="bold" text-anchor="middle">검색 결과가 없습니다</text>
    <text x="850" y="590" fill="#8C8C8C" font-family="Inter" font-size="14" text-anchor="middle">입력하신 거래처명에 일치하는 발주서가 존재하지 않습니다.</text>
  </g>
</g>
</svg>
```
