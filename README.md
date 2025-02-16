# Waifu Deckbuilder

A LÖVE2D card game that combines dating sim elements with deckbuilding mechanics, inspired by Balatro.

## Features

- Poker-based hand scoring system
- Corruption mechanics that modify suit multipliers
- Multiple stages with increasing difficulty
- Round-based gameplay with hand and discard management
- Dynamic scoring preview system
- Visual feedback for all game actions

## Requirements

- LÖVE 11.4 or higher
- Lua 5.1+

## Installation

1. Install LÖVE from https://love2d.org/
2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/deckbuilder.git
   cd deckbuilder
   ```
3. Run the game:
   ```bash
   love .
   ```

## How to Play

1. **Basic Gameplay**
   - Select cards by clicking on them
   - Play selected cards with SPACE or the Play button
   - Discard unwanted cards with D or the Discard button
   - Each round gives you 3 hands and 3 discard opportunities

2. **Scoring System**
   - Form poker hands for maximum points
   - Higher value hands give better multipliers
   - Suit-specific corruption multipliers affect scoring
   - Meet the target score to advance to the next round

3. **Hand Types (from highest to lowest)**
   - Royal Flush (1000 base × 15x)
   - Straight Flush (750 base × 12x)
   - Four of a Kind (600 base × 10x)
   - Full House (500 base × 8x)
   - Flush (400 base × 6x)
   - Straight (300 base × 5x)
   - Three of a Kind (200 base × 4x)
   - Two Pair (100 base × 3x)
   - One Pair (50 base × 2x)
   - High Card (10 × card value)

## Controls

- Left Click: Select/deselect cards
- SPACE: Play selected cards
- D: Discard selected cards
- Mouse: Click UI buttons for actions

## License

MIT License - See LICENSE file for details 