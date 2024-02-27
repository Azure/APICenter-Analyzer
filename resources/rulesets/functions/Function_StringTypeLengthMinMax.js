import { validateSubschemas } from "../function_utils/validate-subschemas";

/**
 *
 * This custom function checks for string definations such as min/max length
 * requires a vaildate-subschema utlits code****
 *
 */
export default function (schema, _opts, { path }) {
    return validateSubschemas(schema, path, stringBoundaryErrors);
};

function stringBoundaryErrors(schema, path) {
    const errors = [];
    if (schema.type !== "string") {
        return errors;
    }
    if (isUndefinedOrNull(schema.enum)) {
        if (isUndefinedOrNull(schema.minLength)) {
            errors.push({
                message: "Should define a minLength for {{property}}",
                path,
            });
        }
        if (isUndefinedOrNull(schema.maxLength)) {
            errors.push({
                message: "Should define a maxLength for {{property}}",
                path,
            });
        }
        if (
            !isUndefinedOrNull(schema.minLength) &&
            !isUndefinedOrNull(schema.maxLength) &&
            schema.minLength > schema.maxLength
        ) {
            errors.push({
                message:
                    "MinLength must be less than maxLength for {{property}}",
                path,
            });
        }
    }
    return errors;
}

function isUndefinedOrNull(obj) {
    return obj === undefined || obj === null;
}
