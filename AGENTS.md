### QA GENIE CORE RULES

FIREBASE ID,PACKAGE_NAME,APPLICATIONID should be never changed

## PACKAGE_NAME : :com.enaykumar.qagenie

## APPLICATIONID :com.enaykumar.qagenie

## FIREBASE ID :qa-genie-ai

AGENTS SHOULD FOLLOW BELOW RULES BEFORE PLANING OR FIXING

- 1.ONLY TWO TYPES OF ACCOUNTS ALLOWED -USER AND GUESTS(FIRST TIME GUEST(6QUOTA PER DAY),RETURNING GUEST(1QUOTA PER DAY))
- 2.ONLY TWO TIERS CORE AND PRO - CORE IS DEFAULT FOR ALL BUT RETURNING GUESTS(ONLY 1QUOTA)
- 3.All screens should be seamless, no lags in between navigation, and also I don't want to see any loading screens or something. Everything should be seamledss.
- 4.Any gets should not be able to see delete account or logout , and gets are not allowed to give feedback, but we collect feedback starts from the first guests(6quota) from any guess.
- 5.We should always try to give AI test cases only, so we should make sure at most the AI won't fail to give the good test cases, and And if the call already went (the API call already went) and we get nothing, then we go to the fallback, but no retries. If the call not went, then we can retry AI.
- 6.If we get some good cases and some bad test cases from the AI, the fall back generator should not produce all the test cases but only those that are not good. Try to repair them by the repair engine with the same fall back generator, you know, the fall back domains.
- 7.One one ad should always be preloaded, so every time we should get the ad instantly. Okay.
- 8.In prod mode, offline is not allowed when trying to generate or export in test cases or exporting summary should show no internet screen, but offline is allowed when editing the test cases, checking on system assisting, or checking on test suits editing and saving. These all can be done in offline also.
- 9.If the user deletes the account, he should be automatically moved to a new guest account which has only one quota. And from this new guest account, if the user tries to link with a Google account, the same Google account which is deleted is not allowed and cooled down for 2 hours. Not in the device base, but everywhere, in any other device also, these emails should be blocked for 24 hours. User can use another email in this (in this mobile, say mobile no problem), and if he tries to move from this returning guests to your user, then the data and the quota are not reflected, not merging to the user account.
- 10.I should not see any snack bars in the production app. Everything should be in a dialog box, and it should be human-readable. I don't wanna let any error happen, so our system should be ready to handle the errors and give us always users a good result that the user can be happy. But I don't want to show any errors. 11.
- 11.I allow quota display in only one place, which is generate hint. No other places should be shown the quarter limit. Okay, and when the pop-up shows "You're out of your limit," something like that, you should show the exact time how long it may take to reset so that the user won't be confused. That he has clarity when he wants to come back.
- 12.only ad rewared quotas if core,core is default for users or guests but returning guest only one deffrence is he gets 1quota instead of 6 but still he is also core
- 14.We only collect Matrix email,deviceid,etc Whatever you think,But we never collect Test cases ,modules,Anything related to test cases only exception is We collect full issue reports, but we never sync live. We only sync one field, which is status. The status should be linked to Firebase and the app so that users can see what the status is. We don't sync every day we sync once for 14 days only.
- 17.We are not planning to release the pro version in the first build. At the initial, we are not releasing it, but later, after getting feedback from users and pro interest taps, we decide the price and then we launch. But the pro implementation should be ready; it should be ready within, like, only one or two modifications should be good to go. We should be ready with the pro implementation, but we are not launching yet.
- 18.We always try to reduce the usage of reads, writes, and checks while giving full features and full checks. Okay, we can batch the reads, writes, and checks, but still the security is more with more priority at the same time. High priority is cost; okay, we should always think about the cost. It should be less, and the revenue should be more.
- 19.The fallback generator should generate test cases, like nearly 70% of AI test cases; it should look like AI test cases.

##### VERY IMPORTANT

AGENTS SHOULD ACKNWLWDGE IN THE CHAT THAT THEY READ AND FOLLOWING RULES FROM AGENTS.MD
