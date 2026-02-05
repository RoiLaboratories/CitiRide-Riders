const { setGlobalOptions } = require("firebase-functions");
const { onCall } = require("firebase-functions/v2/https");
const axios = require("axios");

// Limit concurrent function instances
setGlobalOptions({ maxInstances: 10 });

// Paystack Card Verification Function
exports.verifyCard = onCall(async (req) => {
  const { cardNumber, expiryMonth, expiryYear, cvv, email } = req.data;

  if (!cardNumber || !expiryMonth || !expiryYear || !cvv || !email) {
    return { success: false, message: "Missing required card info" };
  }

  try {
    const response = await axios.post(
      "https://api.paystack.co/charge",
      {
        email: email,
        amount: 100,
        card: {
          number: cardNumber,
          cvv: cvv,
          expiry_month: expiryMonth,
          expiry_year: expiryYear,
        },
      },
      {
        headers: {
          Authorization: `Bearer sk_test_9228b526ae411ab46cf6563a6192c59e6dc9e56a`,
          "Content-Type": "application/json",
        },
      }
    );

    // Paystack returns authorization details if successful
    return {
      success: true,
      message: "Card verified successfully",
      data: response.data.authorization,
    };
  } catch (err) {
    console.error("Paystack Error:", err.response?.data || err.message);
    return {
      success: false,
      message: err.response?.data?.message || "Failed to verify card",
    };
  }
});
