# AI/ML/DL 규율
> core.md 위에 적용

## 공통 실험 관리
- 베이스라인 먼저 확립. 베이스라인 없이 모델 개선 주장 금지.
- 한 번에 하나만 변경. 여러 변경 동시 적용 시 원인 특정 불가.
- 실험 결과 기록 필수: 메트릭 + 변경점 + 판단(keep/discard/refine).

## GPU 효율
- 텐서 생성 시 device= 명시. CPU 생성 후 .cuda() 금지.
- forward 내 상수 → register_buffer로 이동.
- Boolean 인덱싱 → Float 마스크 곱셈 (shape 고정 유지).
- pin_memory=True + non_blocking=True, GPU 전송 후 연산.

## 데이터 전처리
- 전처리 파이프라인과 모델을 분리. 전처리 코드 안에서 모델 학습하지 않는다.
- train 데이터로 fit한 전처리(스케일러, 인코더 등)를 val/test에 transform만 적용. 역방향 누수 금지.

## 재현성
- 시드 고정 (random, numpy, torch, cuda).
- 환경 기록: Python 버전, 패키지 버전, GPU 모델.

---

## 태스크별 규율

### 분류 (Classification)
- 베이스라인: majority class.
- 평가: F1 기반 (accuracy 단독 사용 금지). 클래스 불균형 시 macro F1.
- 라벨 품질 > 모델 크기. 첫 모델의 confusion matrix 분석 후, 오분류 패턴이 라벨 노이즈를 시사하면 모델 변경 전에 라벨 검토.
- 데이터 분할: stratify 사용 권장. 분할 비율과 근거를 기록.
- 개선 순서: 데이터 품질/양 → 피처 엔지니어링 → 모델 변경 → 앙상블. 이전 단계를 충분히 탐색하지 않고 다음 단계로 넘어가지 않는다.

### 회귀 (Regression)
- 베이스라인: 평균값 예측.
- 평가: MAE, RMSE, MAPE 병행. 단일 메트릭 금지.
- 잔차 분포 확인: 정규성, 이분산성 체크.

### 시계열 예측 (Time Series Forecasting)
- 베이스라인: naive(직전값 반복), 이동평균.
- 시간 순서 유지: 랜덤 split 금지, 시간 기반 train/val/test.
- 데이터 누수 점검: 미래 정보가 피처에 포함되지 않았는지 확인.
- 잔차 분석: 시간대별·구간별 오차 패턴 확인 후 피처 수정.

### 이상 탐지 (Anomaly Detection)
- 베이스라인: 통계 기반 (p99, z-score, IQR).
- 평가: precision-recall 기반 (accuracy 금지).
- 임계값 민감도: threshold 변경에 따른 성능 변화 확인.
- 오탐/미탐 비용 비대칭: 도메인별 비용 정의 후 최적화.

### 객체 탐지 (Object Detection)
- 베이스라인: pretrained backbone (YOLO, DETR 등).
- 평가: mAP@IoU, 클래스별 AP.
- 앵커/스케일 설정이 성능에 큰 영향 — 데이터 분포 확인 후 설정.

### 세그멘테이션 (Segmentation)
- 베이스라인: pretrained encoder-decoder.
- 평가: IoU(mIoU), Dice coefficient.
- 클래스 불균형이 분류보다 더 심함 → loss 설계 중요.

### 클러스터링 (Clustering)
- 베이스라인: K-Means.
- 평가: silhouette score + 도메인 전문가 정성 평가 병행.
- k 선정: elbow method + 도메인 지식.

### 자연어 처리 (NLP)
- 토크나이저 선택이 성능에 직접 영향 — 도메인 데이터 포함 여부 확인.
- 다국어: 언어별 토큰 비율 확인.
- 텍스트 길이 분포 → max_length 설정 근거.

### 생성 모델 (Generation)
- 평가: 자동 메트릭(BLEU, perplexity) + 정성 평가 병행.
- 다양성 vs 품질 트레이드오프 명시.
- GAN 학습 불안정: mode collapse 모니터링.

### LM/LLM 프리트레이닝
- LR 스케줄: WSD(Warmup-Stable-Decay) 고려. cosine decay가 항상 최선은 아님.
- Loss 발산 시: LR 낮추고 이전 체크포인트에서 재시작.
- 체크포인트: optimizer state + scheduler state 함께 저장.
- 커리큘럼: 데이터 품질 오름차순 배치 시 constant LR과 궁합 좋음.

### LM/LLM 파인튜닝
- LoRA vs Full: Full이 성능 높지만 catastrophic forgetting 위험 큼.
- LoRA도 forgetting 발생 — "PEFT니까 안전하다"는 오해.
- Forgetting 방지: 범용 데이터 20-30% 혼합.
- 평가: 태스크 메트릭 + 범용 능력 회귀 테스트 병행.

### 강화학습 (Reinforcement Learning)
- 베이스라인: random policy.
- reward shaping이 학습 방향을 결정 — 신중하게 설계.
- 환경 시뮬레이터 재현성 확보.

### 정의되지 않은 태스크
- 위 카테고리에 해당하지 않으면 사용자에게 설명 요청:
  "이 태스크의 평가 메트릭, 베이스라인, 주요 주의사항을 알려주세요."
- 사용자 응답을 프로젝트 오버라이드로 저장 → 다음 세션에서 재활용.
