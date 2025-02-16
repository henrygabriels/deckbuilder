local RunManager = {}
RunManager.__index = RunManager

-- Stage thresholds for minimum scores
RunManager.STAGE_THRESHOLDS = {
    100,    -- Stage 1
    250,    -- Stage 2
    500,    -- Stage 3
    1000,   -- Stage 4
    2000,   -- Stage 5
    4000,   -- Stage 6
    8000,   -- Stage 7
    16000   -- Stage 8
}

-- Bonus thresholds (percentage above minimum for extra rewards)
RunManager.BONUS_THRESHOLDS = {
    1.5,    -- 50% above minimum
    2.0,    -- 100% above minimum
    3.0     -- 200% above minimum
}

-- Create a new run manager
function RunManager.new()
    local self = setmetatable({}, RunManager)
    
    -- Run state
    self.currentStage = 1
    self.currentRound = 1
    self.roundsRemaining = 3
    self.bestScoreThisStage = 0
    self.scores = {}  -- Track scores for each round
    self.stageCleared = false
    self.gameOver = false
    
    return self
end

-- Get current stage threshold
function RunManager:getCurrentThreshold()
    return RunManager.STAGE_THRESHOLDS[self.currentStage]
end

-- Check if a score meets the current stage threshold
function RunManager:checkScore(score)
    local threshold = self:getCurrentThreshold()
    
    -- Track best score this stage
    if score > self.bestScoreThisStage then
        self.bestScoreThisStage = score
    end
    
    -- Check if stage is cleared
    if score >= threshold then
        self.stageCleared = true
    end
    
    -- Store score for this round
    self.scores[self.currentRound] = score
    
    -- Check for bonus rewards
    local bonuses = {}
    for i, multiplier in ipairs(RunManager.BONUS_THRESHOLDS) do
        if score >= threshold * multiplier then
            table.insert(bonuses, {
                tier = i,
                multiplier = multiplier
            })
        end
    end
    
    return {
        score = score,
        threshold = threshold,
        cleared = score >= threshold,
        bonuses = bonuses
    }
end

-- Advance to next round
function RunManager:nextRound()
    self.currentRound = self.currentRound + 1
    self.roundsRemaining = self.roundsRemaining - 1
    
    -- Check if stage is complete
    if self.currentRound > 3 then
        if not self.stageCleared then
            self.gameOver = true
            return false, "Breakup! Failed to meet stage threshold."
        end
        
        -- Advance to next stage
        self.currentStage = self.currentStage + 1
        self.currentRound = 1
        self.roundsRemaining = 3
        self.bestScoreThisStage = 0
        self.stageCleared = false
        self.scores = {}
        
        if self.currentStage > 8 then
            return true, "Congratulations! You've completed all stages!"
        end
        
        return true, string.format("Stage %d complete!", self.currentStage - 1)
    end
    
    return true, ""
end

-- Get current game state
function RunManager:getState()
    return {
        stage = self.currentStage,
        round = self.currentRound,
        roundsRemaining = self.roundsRemaining,
        threshold = self:getCurrentThreshold(),
        bestScore = self.bestScoreThisStage,
        stageCleared = self.stageCleared,
        gameOver = self.gameOver,
        scores = self.scores
    }
end

return RunManager 