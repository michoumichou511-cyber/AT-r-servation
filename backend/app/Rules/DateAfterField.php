<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\DataAwareRule;
use Illuminate\Contracts\Validation\ValidationRule;

class DateAfterField implements DataAwareRule, ValidationRule
{
    protected array $data = [];

    public function __construct(protected string $otherField, protected string $otherLabel = '') {}

    public function setData(array $data): static
    {
        $this->data = $data;

        return $this;
    }

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        $otherValue = $this->data[$this->otherField] ?? null;

        if ($otherValue && $value && strtotime($value) <= strtotime($otherValue)) {
            $label = $this->otherLabel ?: $this->otherField;
            $fail("La date doit être postérieure à {$label}.");
        }
    }
}
