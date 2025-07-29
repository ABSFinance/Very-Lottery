import React from 'react';
import './GameSelector.css';

const GameCard = ({ title, price, duration, contract, onClick }) => {
  return (
    <div className="game-card" onClick={onClick}>
      <div className="game-card-header">
        <h3>{title}</h3>
        <div className="game-type-badge">{contract}</div>
      </div>
      <div className="game-card-content">
        <div className="game-price">
          <span className="price-label">Ticket Price:</span>
          <span className="price-value">{price}</span>
        </div>
        <div className="game-duration">
          <span className="duration-label">Duration:</span>
          <span className="duration-value">{duration}</span>
        </div>
      </div>
      <div className="game-card-footer">
        <button className="select-game-btn">Select Game</button>
      </div>
    </div>
  );
};

const GameSelector = ({ onGameSelect }) => {
  const games = [
    {
      id: 1,
      title: "Cryptolotto 1 Day",
      description: "Daily lottery with transparent blockchain technology",
      price: "0.01 VERY",
      duration: "24 hours",
      address: process.env.REACT_APP_CRYPTOLOTTO_1DAY
    },
    {
      id: 2,
      title: "Cryptolotto 7 Days",
      description: "Weekly lottery with bigger prizes",
      price: "0.02 VERY",
      duration: "7 days",
      address: process.env.REACT_APP_CRYPTOLOTTO_7DAYS
    },
    {
      id: 3,
      title: "Cryptolotto 6 Hours",
      description: "Quick lottery every 6 hours",
      price: "0.005 VERY",
      duration: "6 hours",
      address: process.env.REACT_APP_CRYPTOLOTTO_6HOURS
    },
    {
      id: 4,
      title: "Cryptolotto 1 Hour",
      description: "Fast-paced hourly lottery",
      price: "0.01 VERY",
      duration: "1 hour",
      address: process.env.REACT_APP_CRYPTOLOTTO_1HOUR
    },
    {
      id: 5,
      title: "Cryptolotto 10 Minutes",
      description: "Ultra-fast lottery every 10 minutes",
      price: "0.005 VERY",
      duration: "10 minutes",
      address: process.env.REACT_APP_CRYPTOLOTTO_10MINUTES
    }
  ];

  return (
    <div className="game-selector">
      <div className="game-selector-header">
        <h2>Choose Your Game</h2>
        <p>Select from our variety of lottery games with different durations and prizes</p>
      </div>
      <div className="game-cards-grid">
        {games.map((game, index) => (
          <GameCard
            key={index}
            title={game.title}
            price={game.price}
            duration={game.duration}
            contract={game.contract}
            onClick={() => onGameSelect(game)}
          />
        ))}
      </div>
    </div>
  );
};

export default GameSelector; 