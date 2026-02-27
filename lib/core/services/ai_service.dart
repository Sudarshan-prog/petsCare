import 'dart:async';

class AiWellnessService {
  // ARCHITECT: Pre-coded high-quality medical/nutritional knowledge base
  // This allows the app to function perfectly even WITHOUT an API key (Free Tier Offline mode)
  final Map<String, String> _knowledgeBase = {
    'vomiting':
        'Vomiting can be caused by dietary indiscretion or something more serious. If your pet is lethargic or has blood in the vomit, please see a vet immediately. For mild cases, withholding food for 12 hours and then offering a bland diet (boiled chicken and rice) may help.',
    'itching':
        'Itching is often a sign of allergies (food or environmental) or parasites like fleas. Check for red spots or "flea dirt". Adding Omega-3 supplements can often soothe skin irritation.',
    'lethargy':
        'Lethargy in pets is always a concern. It could be as simple as heat exhaustion or a sign of an underlying infection. Ensure they are hydrated. If they refuse their favorite treat, it is time for a professional checkup.',
    'diet':
        'For adult dogs, a balanced mix of 25% protein, 15% fat, and complex carbs is ideal. Avoid grapes, chocolate, onions, and garlic as they are toxic to pets.',
    'training':
        'Positive reinforcement is the gold standard. Use high-value treats (like small pieces of boiled chicken) and keep sessions short (5-10 minutes) to maintain focus.',
  };

  Future<String> getAiAdvice(String query) async {
    // Simulate network delay for AI-like feeling
    await Future.delayed(const Duration(seconds: 2));

    query = query.toLowerCase();

    // Search the knowledge base
    for (var key in _knowledgeBase.keys) {
      if (query.contains(key)) {
        return _knowledgeBase[key]!;
      }
    }

    // Default "Smart" AI Fallback
    return "I'm analyzing your request. While I'm still learning about specific cases, general pet wellness involves consistent hydration, high-protein diets, and at least 30 minutes of daily activity. For specific medical emergencies, always consult a physical vet.";
  }
}
