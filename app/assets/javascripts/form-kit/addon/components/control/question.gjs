import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import FKLabel from "form-kit/components/label";
import { eq } from "truth-helpers";
import uniqueId from "discourse/helpers/unique-id";
import i18n from "discourse-common/helpers/i18n";

export default class FKControlQuestion extends Component {
  @action
  handleInput(event) {
    this.args.set(event.target.value);
  }

  <template>
    <div class="form-kit__inline-radio">
      {{#let (uniqueId) as |uuid|}}
        <FKLabel @fieldId={{uuid}} class="form-kit__control-radio__label">
          <input
            name={{@field.name}}
            type="radio"
            value={{true}}
            checked={{eq @value true}}
            class="form-kit__control-radio"
            disabled={{@field.disabled}}
            ...attributes
            id={{uuid}}
            {{on "change" this.handleInput}}
          />

          {{#if @positiveLabel}}
            {{@positiveLabel}}
          {{else}}
            {{i18n "yes_value"}}
          {{/if}}
        </FKLabel>
      {{/let}}

      {{#let (uniqueId) as |uuid|}}
        <FKLabel @fieldId={{uuid}} class="form-kit__control-radio__label">
          <input
            name={{@field.name}}
            type="radio"
            value={{false}}
            checked={{eq @value false}}
            class="form-kit__control-radio"
            disabled={{@field.disabled}}
            ...attributes
            id={{uuid}}
            {{on "change" this.handleInput}}
          />

          {{#if @negativeLabel}}
            {{@negativeLabel}}
          {{else}}
            {{i18n "no_value"}}
          {{/if}}
        </FKLabel>
      {{/let}}
    </div>
  </template>
}