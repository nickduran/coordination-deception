Coordination in Deceptive Conversations (PLOS ONE)
===================

Sample code and data for conducting analyses to evaluate multi-modal coordination during interpersonal deception. Code written for MATLAB and R.



Motion: 
===================

Code (preparation)
-------------

> **Relevant Files:**
> - MotionAnalysisCoordinatesRegions.m, MotionAnalysisGenerateFlow.m, MotionAnalysisGetSynchrony.m

1) In MotionAnalysisCoordinatesRegions.m: Step 1 in generating motion energy flows: Takes in videos of interaction and allows user to interactively mark coordinates on the screen that separate out each participants' movements and regions of interest (head, mid, and lower body). Coordinates saved in data array structure to be used in MotionAnalysisGenerateFlow.m (below).

2) In MotionAnalysisGenerateFlow.m: Step 2 in generating motion energy flows: Takes in data structure from above and all videos of interaction. Based on coordinates, splits videos into appropriate regions for each participant to perform the frame subtraction method on pixelation differences (i.e., movement displacement). These movement displacement values, for each targeted region of interest, are saved as text files in folder "motionSeriesRegions" to be used in MotionAnalysisGetSynchrony.m below. 

3) In MotionAnalysisGetSynchrony.m: Step 3 in generating motion energy flows: Main code for generating windowed-lagged cross correlation over the two movement displacement time series for each dyad.

Data (deidentified)
-------------

> **Relevant Files:**
> - synchronyMovementRapp.csv

1) File contains WLCC scores for each time lag, as well as rapport scores. Explanation for each column and codes:
> - Column A: Real vs Virtual Pairs; 1 = Real, 2 = Virtual 
> - Column B: Dyad number
> - Colmnn C: Order of deceptive conversation; 2 = First, 3 = Second
> - Column D: Did conversation involve deception or not; 0 = No Deception, 1 = Deception
> - Column E: Did conversation involve conflict or not; 1 = Disagreement, 2 = Agreement
> - Column F: Body region of Participant 1 analyzed: 1 = head/shoulders, 3 = mid-thigh/feet 
> - Column G: Body region of Participant 2 analyzed: 1 = head/shoulders, 3 = mid-thigh/feet
> - Column H: Sex
> - Column I: Topic of conversation (varies across 10 possible topics)
> - Column J: Average response between participants to question "I felt very close to my partner"
> - Column K: Average response between participants to question "I felt that my partner understood what I was saying"
> - Column L: Average response between participants to question "I felt that I understood what my partner was saying"
> - Column M: Same as K, but absolute difference between participants
> - Column N: Same as L, but absolute difference between participants
> - Column O: Same as M, but absolute difference between participants
> - Columns P-BX: lagged differences between participants' movements (at increments of 1/6 of a second up to 5000ms), values in each cell correspond to WLCC scores, positive lags correspond to DA following and negative lags correspond to Naive following 


Speech:
===================

Data (deidentified)
-------------

> **Relevant Files:**
> - synchronySpeechRapp.csv

1) File contains CRQA DVs for speech rate, as well as rapport scores. Explanation for each column and codes:
> - Column A: Real vs Virtual Pairs; 1 = Real, 2 = Virtual 
> - Column B: Dyad number
> - Colmnn C: Order of deceptive conversation; 2 = First, 3 = Second
> - Column D: Did conversation involve deception or not; 0 = No Deception, 1 = Deception
> - Column E: Did conversation involve conflict or not; 1 = Disagreement, 2 = Agreement
> - Column F: Sex
> - Column G: Age
> - Column H: Topic of conversation (varies across 10 possible topics)
> - Column I: Average response between participants to question "I felt very close to my partner"
> - Column J: Average response between participants to question "I felt that my partner understood what I was saying"
> - Column K: Average response between participants to question "I felt that I understood what my partner was saying"
> - Column L: Same as I, but absolute difference between participants
> - Column M: Same as J, but absolute difference between participants
> - Column N: Same as K, but absolute difference between participants
> - Column O: Speech Rate RR
> - Column O: Speech Rate DET
> - Column O: Speech Rate L
> - Column O: Speech Rate LMAX
> - Column O: Speech Rate ENTR
> - Column O: Speech Rate T2

R Code For Analyses: 
===================

> **Relevant Files:**
> - MAIN Movement Speech FINAL.r

1) File runs the analyses described in the Mixed Effects Models section of paper, using data from synchronyMovementRapp.csv and synchronySpeechRapp.csv described above


