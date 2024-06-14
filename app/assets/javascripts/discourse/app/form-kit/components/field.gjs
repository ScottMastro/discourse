import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { assert } from "@ember/debug";
import { hash } from "@ember/helper";
import { action, get } from "@ember/object";
import FKControlCheckbox from "discourse/form-kit/components/control/checkbox";
import FKControlCode from "discourse/form-kit/components/control/code";
import FKControlComposer from "discourse/form-kit/components/control/composer";
import FKControlIcon from "discourse/form-kit/components/control/icon";
import FKControlImage from "discourse/form-kit/components/control/image";
import FKControlInput from "discourse/form-kit/components/control/input";
import FKControlMenu from "discourse/form-kit/components/control/menu";
import FKControlQuestion from "discourse/form-kit/components/control/question";
import FKControlRadioGroup from "discourse/form-kit/components/control/radio-group";
import FKControlSelect from "discourse/form-kit/components/control/select";
import FKControlText from "discourse/form-kit/components/control/text";
import FKControlToggle from "discourse/form-kit/components/control/toggle";
import FKControlWrapper from "discourse/form-kit/components/control-wrapper";
import FKRow from "discourse/form-kit/components/row";

export default class FormField extends Component {
  @tracked field;

  constructor() {
    super(...arguments);

    assert(
      "Nested property paths in @name are not supported.",
      typeof this.args.name !== "string" || !this.args.name.includes(".")
    );

    this.field = this.args.registerField(this.args.name, {
      validate: this.args.validate,
      disabled: this.args.disabled,
      validation: this.args.validation,
      onSet: this.args.onSet,
    });
  }

  willDestroy() {
    this.args.unregisterField(this.args.name);

    super.willDestroy();
  }

  get value() {
    return get(this.args.data, this.args.name);
  }

  get errors() {
    return { [this.args.name]: this.args.errors?.[this.args.name] };
  }

  get hasErrors() {
    return Object.values(this.errors).flat().compact().length;
  }

  get showMeta() {
    return this.args.showMeta ?? true;
  }

  @action
  setValue(value) {
    this.args.set(this.args.name, value);
  }

  @action
  set(value) {
    if (this.field.onSet) {
      this.field.onSet(value, { set: this.args.set });
    } else {
      this.setValue(value);
    }
  }

  get wrapper() {
    if (this.args.size) {
      return <template>
        <FKRow as |row|>
          <row.Col @size={{@size}}>
            {{yield}}
          </row.Col>
        </FKRow>
      </template>;
    } else {
      return <template>
        {{! template-lint-disable no-yield-only }}
        {{yield}}
      </template>;
    }
  }

  <template>
    <this.wrapper @size={{@size}}>
      {{yield
        (hash
          Code=(component
            FKControlWrapper
            component=FKControlCode
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          Question=(component
            FKControlWrapper
            component=FKControlQuestion
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          Text=(component
            FKControlWrapper
            component=FKControlText
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          Checkbox=(component
            FKControlCheckbox
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          Image=(component
            FKControlWrapper
            component=FKControlImage
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          Composer=(component
            FKControlWrapper
            component=FKControlComposer
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          Icon=(component
            FKControlWrapper
            component=FKControlIcon
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          Toggle=(component
            FKControlWrapper
            component=FKControlToggle
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          Menu=(component
            FKControlWrapper
            component=FKControlMenu
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          Select=(component
            FKControlWrapper
            component=FKControlSelect
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          Input=(component
            FKControlWrapper
            component=FKControlInput
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          RadioGroup=(component
            FKControlWrapper
            component=FKControlRadioGroup
            setValue=this.setValue
            value=this.value
            errors=this.errors
            hasErrors=this.hasErrors
            triggerValidationFor=@triggerValidationFor
            field=this.field
            set=this.set
          )
          setValue=this.setValue
        )
      }}
    </this.wrapper>
  </template>
}
