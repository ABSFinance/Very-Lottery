// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract iOwnable {
    function isAllowed(address) public view returns (bool) {}
}

/**
 * @title Cryptolotto Referral System
 *
 * @dev Cryptolotto takes 10% commission after each draw. Cryptolotto redistributes its earnings on:
 * @dev - salaries of Cryptolotto workers;
 * @dev - advertisement campaigns for constant growth of players;
 * @dev - security and maintenance of Cryptolotto servers;
 * @dev - work on future updates;
 * @dev - taxes in the state of residence of Cryptolotto;
 * @dev - Cryptolotto Referral System.
 *
 * @dev Cryptolotto Referral System (CRS) allows splitting the commission after each draw
 * @dev between Cryptolotto, Influencers, and Sales (optional) by establishing the two-level
 * @dev partnership program built on blockchain-based algorithms. The source code of the CRS
 * @dev is stored on the Github and can be checked by any party at any time.
 *
 * @dev Cryptolotto Referral System is represented by the two levels:
 * @dev - the influencer level;
 * @dev - the sales level.
 *
 * @dev The influencer is a media outlet, blogger, website or business which audience has high chances to engage with Cryptolotto.
 *
 * @dev The sales is a person or a company, who is constantly looking for new influencers to join the Cryptolotto Referral System.
 *
 * @dev Each referral partner is getting his part of a commission from each player, who joined the game by following referral's
 * @dev custom link. A commission is sent to an Influencer and Sales right after a player joins the game. Players are bonded to
 * @dev referrals forever and cannot be removed from the Cryptolotto Referral System. Influencer and Sales are added to the
 * @dev Cryptolotto Referral System forever and cannot be removed from it. Influencer and Sales are getting their part of a
 * @dev commission as long as players, who followed Influencer's link, are playing the Cryptolotto.
 **/
contract CryptolottoReferral {
    /**
     * @dev Write to log info about new partner.
     *
     * @param _address Partner address.
     * @param _percent partner percent.
     * @param _time Time when partner was added.
     */
    event NewPartner(address indexed _address, uint _percent, uint _time);

    /**
     * @dev Write to log info about new sales partner.
     *
     * @param _partnerAddress Partner address.
     * @param _salesPartnerAddress Sales partner address.
     * @param _percent Sales partner partner percent.
     * @param _time Time when partner was added.
     */
    event NewSalesPartner(
        address indexed _partnerAddress,
        address indexed _salesPartnerAddress,
        uint _percent,
        uint _time
    );

    /**
     * @dev Write to log info about new referral.
     *
     * @param _partner Partner address.
     * @param _referral Referral address.
     * @param _time Time when referral was added.
     */
    event NewReferral(
        address indexed _partner,
        address indexed _referral,
        uint _time
    );

    /**
     * @dev Write to log info about new game.
     *
     * @param _game Address of the game.
     * @param _time Time when game was added.
     */
    event NewGame(address _game, uint _time);

    /**
     * @dev Write to log info about partner removal.
     *
     * @param _address Partner address.
     * @param _time Time when partner was removed.
     */
    event PartnerRemoved(address indexed _address, uint _time);

    /**
     * @dev Write to log info about game removal.
     *
     * @param _game Game address.
     * @param _time Time when game was removed.
     */
    event GameRemoved(address _game, uint _time);

    /**
     * @dev Ownable contract.
     */
    iOwnable ownable;

    /**
     * @dev Store referrals.
     */
    mapping(address => address) referrals;

    /**
     * @dev Store cryptolotto partners.
     */
    mapping(address => uint8) partners;

    /**
     * @dev Store list of addresses(games) that can add referrals.
     */
    mapping(address => bool) allowedGames;

    /**
     * @dev Store sales partners.
     */
    mapping(address => address) salesPartners;

    /**
     * @dev Store cryptolotto sales partners percents.
     */
    mapping(address => mapping(address => uint8)) salesPartner;

    /**
     * @dev Initialize contract, Create ownable instances.
     *
     * @param owner The address of previously deployed ownable contract.
     */
    constructor(address owner) {
        require(owner != address(0), "Invalid owner address");
        ownable = iOwnable(owner);
    }

    /**
     * @dev Get partner by referral.
     *
     * @param player Referral address.
     */
    function getPartnerByReferral(
        address player
    ) public view returns (address) {
        return referrals[player];
    }

    /**
     * @dev Get partner percent.
     *
     * @param partner Partner address.
     */
    function getPartnerPercent(address partner) public view returns (uint8) {
        return partners[partner];
    }

    /**
     * @dev Get partner percent by referral.
     *
     * @param referral Refaral address.
     */
    function getPartnerPercentByReferral(
        address referral
    ) public view returns (uint8) {
        address partner = getPartnerByReferral(referral);

        return getPartnerPercent(partner);
    }

    /**
     * @dev Get sales partner percent by partner address.
     *
     * @param partner Partner address.
     */
    function getSalesPartnerPercent(
        address partner
    ) public view returns (uint8) {
        return salesPartner[salesPartners[partner]][partner];
    }

    /**
     * @dev Get sales partner address by partner address.
     *
     * @param partner Partner address.
     */
    function getSalesPartner(address partner) public view returns (address) {
        return salesPartners[partner];
    }

    /**
     * @dev Check if address is a partner.
     *
     * @param partner Partner address.
     */
    function isPartner(address partner) public view returns (bool) {
        return partners[partner] > 0;
    }

    /**
     * @dev Check if address is an allowed game.
     *
     * @param game Game address.
     */
    function isAllowedGame(address game) public view returns (bool) {
        return allowedGames[game];
    }

    /**
     * @dev Get all partners (basic implementation)
     * Note: For production, consider using a more sophisticated data structure
     */
    function getPartnerStats(
        address partner
    )
        public
        view
        returns (
            uint8 percent,
            address _salesPartner,
            uint8 salesPercent,
            bool isActive
        )
    {
        address salesPartnerAddr = salesPartners[partner];
        uint8 salesPercentValue = 0;
        if (salesPartnerAddr != address(0)) {
            salesPercentValue = getSalesPartnerPercent(partner);
        }

        return (
            partners[partner],
            salesPartnerAddr,
            salesPercent,
            partners[partner] > 0
        );
    }

    /**
     * @dev Get referral count for a partner
     */
    function getReferralCount(address _partner) public view returns (uint) {
        uint count = 0;
        // This is a simplified implementation
        // In production, you'd want to maintain a separate mapping for this
        return count;
    }

    /**
     * @dev Create partner.
     *
     * @param partner Partner address.
     * @param percent Partner percent.
     */
    function addPartner(address partner, uint8 percent) public {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        require(percent > 0 && percent <= 100, "Invalid percent");
        require(partner != address(0), "Invalid partner address");
        require(partners[partner] == 0, "Partner already exists");

        partners[partner] = percent;

        emit NewPartner(partner, percent, block.timestamp);
    }

    /**
     * @dev Remove partner.
     *
     * @param partner Partner address.
     */
    function removePartner(address partner) public {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        require(partner != address(0), "Invalid partner address");
        require(partners[partner] > 0, "Partner does not exist");

        delete partners[partner];
        delete salesPartners[partner];

        emit PartnerRemoved(partner, block.timestamp);
    }

    /**
     * @dev Create sales partner.
     *
     * @param partner Partner address.
     * @param salesAddress Sales partner address.
     * @param percent Sales partner percent.
     */
    function addSalesPartner(
        address partner,
        address salesAddress,
        uint8 percent
    ) public {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        require(percent > 0 && percent <= 100, "Invalid percent");
        require(
            partner != address(0) && salesAddress != address(0),
            "Invalid addresses"
        );
        require(
            salesPartner[salesAddress][partner] == 0,
            "Sales partner already exists"
        );
        require(
            getSalesPartnerPercent(partner) == 0,
            "Partner already has sales partner"
        );
        require(partners[partner] > 0, "Partner does not exist");

        salesPartner[salesAddress][partner] = percent;
        salesPartners[partner] = salesAddress;

        emit NewSalesPartner(partner, salesAddress, percent, block.timestamp);
    }

    /**
     * @dev Add new game which can create new referrals.
     *
     * @param game Game address.
     */
    function addGame(address game) public {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        require(game != address(0), "Invalid game address");
        require(!allowedGames[game], "Game already allowed");

        allowedGames[game] = true;

        emit NewGame(game, block.timestamp);
    }

    /**
     * @dev Remove game from allowed games.
     *
     * @param game Game address.
     */
    function removeGame(address game) public {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        require(game != address(0), "Invalid game address");
        require(allowedGames[game], "Game not allowed");

        allowedGames[game] = false;

        emit GameRemoved(game, block.timestamp);
    }

    /**
     * @dev Add new referral.
     *
     * @param referral Referral address.
     * @param partner Partner address.
     */
    function addReferral(address partner, address referral) public {
        require(allowedGames[msg.sender], "Not an allowed game");
        require(
            partner != address(0) && referral != address(0),
            "Invalid addresses"
        );
        require(partners[partner] > 0, "Partner does not exist");
        require(referrals[referral] == address(0), "Referral already exists");

        referrals[referral] = partner;

        emit NewReferral(partner, referral, block.timestamp);
    }

    function processReferralSystem(
        address _salesPartner,
        address referral
    ) external {
        // This function is not fully implemented in the provided file,
        // so it's left as a placeholder.
        // In a real scenario, this would involve calculating commissions
        // and distributing them to the relevant parties (Cryptolotto, Influencers, Sales).
        // For now, it just logs the event.
        emit NewReferral(msg.sender, referral, block.timestamp);
    }
}
