import React, { useId } from 'react';
import { clsx } from 'clsx';
import classes from './Input.module.css';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  variant?: 'default' | 'filled';
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({
    className,
    type = 'text',
    label,
    error,
    helperText,
    leftIcon,
    rightIcon,
    variant = 'default',
    id,
    ...props
  }, ref) => {
    const reactId = useId();
    const inputId = id || reactId;
    
    return (
      <div className={classes['input-outer']}>
        {label && (
          <label htmlFor={inputId} className={classes['input-label']}>
            {label}
          </label>
        )}
        
        <div className={classes['input-container']}>
          {leftIcon && (
            <div className={clsx(classes['input-icon'], classes['input-icon-left'])}>
              <span>{leftIcon}</span>
            </div>
          )}
          
          <input
            type={type}
            className={clsx(
              classes['input-root'],
              classes[`input-${variant}`],
              error && classes['input-error'],
              leftIcon && classes['input-has-left'],
              rightIcon && classes['input-has-right'],
              className
            )}
            ref={ref}
            id={inputId}
            {...props}
          />
          
          {rightIcon && (
            <div className={clsx(classes['input-icon'], classes['input-icon-right'])}>
              <span>{rightIcon}</span>
            </div>
          )}
        </div>
        
        {error && (
          <p className={classes['input-error-text']}>{error}</p>
        )}
        
        {helperText && !error && (
          <p className={classes['input-helper-text']}>{helperText}</p>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';

export { Input };