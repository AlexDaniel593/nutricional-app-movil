import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/recipe_provider.dart';
import '../../domain/entities/recipe.dart';
import '../templates/recipe_template.dart';
import '../organisms/recipe/recipe_image_picker.dart';
import '../organisms/recipe/recipe_basic_info_section.dart';
import '../organisms/recipe/recipe_ingredients_form_section.dart';
import '../organisms/recipe/recipe_steps_form_section.dart';

class RecipeFormScreen extends StatefulWidget {
  const RecipeFormScreen({super.key});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _preparationTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _categoryController = TextEditingController();
  
  final List<TextEditingController> _ingredientControllers = [TextEditingController()];
  final List<TextEditingController> _stepControllers = [TextEditingController()];
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  Recipe? _existingRecipe;
  bool _isEditMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Verificar si se está editando una receta existente
    final recipe = ModalRoute.of(context)?.settings.arguments as Recipe?;
    if (recipe != null && !_isEditMode) {
      _existingRecipe = recipe;
      _isEditMode = true;
      _loadRecipeData(recipe);
    }
  }

  void _loadRecipeData(Recipe recipe) {
    _titleController.text = recipe.title;
    _descriptionController.text = recipe.description;
    _preparationTimeController.text = recipe.preparationTime.toString();
    _servingsController.text = recipe.servings.toString();
    _categoryController.text = recipe.category;
    
    // Cargar ingredientes
    _ingredientControllers.clear();
    for (var ingredient in recipe.ingredients) {
      _ingredientControllers.add(TextEditingController(text: ingredient));
    }
    
    // Cargar pasos
    _stepControllers.clear();
    for (var step in recipe.steps) {
      _stepControllers.add(TextEditingController(text: step));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _preparationTimeController.dispose();
    _servingsController.dispose();
    _categoryController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    if (_ingredientControllers.length > 1) {
      setState(() {
        _ingredientControllers[index].dispose();
        _ingredientControllers.removeAt(index);
      });
    }
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    if (_stepControllers.length > 1) {
      setState(() {
        _stepControllers[index].dispose();
        _stepControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null && !_isEditMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona una imagen'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final recipeProvider = context.read<RecipeProvider>();
      
      if (authProvider.currentUser == null) return;

      final ingredients = _ingredientControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
          
      final steps = _stepControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      try {
        if (_isEditMode && _existingRecipe != null) {
          await recipeProvider.modifyRecipe(
            id: _existingRecipe!.id,
            title: _titleController.text,
            description: _descriptionController.text,
            imageFile: _imageFile,
            currentImageUrl: _existingRecipe!.imageUrl,
            ingredients: ingredients,
            steps: steps,
            userId: authProvider.currentUser!.id,
            createdAt: _existingRecipe!.createdAt,
            preparationTime: int.tryParse(_preparationTimeController.text) ?? 0,
            servings: int.tryParse(_servingsController.text) ?? 1,
            category: _categoryController.text,
          );
        } else {
          await recipeProvider.addRecipe(
            title: _titleController.text,
            description: _descriptionController.text,
            imageFile: _imageFile!,
            ingredients: ingredients,
            steps: steps,
            userId: authProvider.currentUser!.id,
            preparationTime: int.tryParse(_preparationTimeController.text) ?? 0,
            servings: int.tryParse(_servingsController.text) ?? 1,
            category: _categoryController.text,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode ? 'Receta actualizada' : 'Receta creada'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();

    return RecipeTemplate(
      title: _isEditMode ? 'Editar Receta' : 'Nueva Receta',
      child: recipeProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecipeImagePicker(
                      imageFile: _imageFile,
                      existingImageUrl: _existingRecipe?.imageUrl,
                      onPickImage: _pickImage,
                    ),
                    const SizedBox(height: 24),
                    RecipeBasicInfoSection(
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      preparationTimeController: _preparationTimeController,
                      servingsController: _servingsController,
                      categoryController: _categoryController,
                    ),
                    const SizedBox(height: 24),
                    RecipeIngredientsFormSection(
                      controllers: _ingredientControllers,
                      onAdd: _addIngredient,
                      onRemove: _removeIngredient,
                    ),
                    const SizedBox(height: 24),
                    RecipeStepsFormSection(
                      controllers: _stepControllers,
                      onAdd: _addStep,
                      onRemove: _removeStep,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveRecipe,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_isEditMode ? 'Actualizar Receta' : 'Guardar Receta'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
